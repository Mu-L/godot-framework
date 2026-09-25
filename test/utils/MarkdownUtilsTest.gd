
func heading_and_inline_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("# Title\n\n**bold** and *italic*")
	assert("# Title" not in bbcode)
	assert("[b]bold[/b]" in bbcode)
	assert("[i]italic[/i]" in bbcode)
	assert("[font_size=32]" in bbcode)
	assert("[b]Title[/b]" not in bbcode)
	pass


func ordered_list_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("1. first\n2. second")
	assert("1. first" in bbcode)
	assert("2. second" in bbcode)
	assert("•" not in bbcode)
	pass


func task_list_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("- [ ] todo\n- [x] done")
	assert("☐" in bbcode)
	assert("☑" in bbcode)
	pass


func blockquote_multiline_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("> line one\n> line two")
	assert("[indent]" in bbcode)
	assert("[table=2]" in bbcode)
	assert(bbcode.count("bg=" + MarkdownUtils.to_bbcode_color(ColorMarkdown.blockquote_bar_color)) == 2)
	assert(bbcode.count("[/cell]") == 4)
	assert("[color=" + MarkdownUtils.to_bbcode_color(ColorMarkdown.blockquote_text_color) + "]" in bbcode)
	assert("[/table][/indent]" in bbcode)
	assert("[bgcolor=" not in bbcode)
	assert("line one" in bbcode and "line two" in bbcode)
	pass


func blockquote_single_line_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("> 快乐韭菜网使用的 chatgpt 3.5 模型")
	assert("[indent]" in bbcode)
	assert("[table=2]" in bbcode)
	assert("bg=" + MarkdownUtils.to_bbcode_color(ColorMarkdown.blockquote_bar_color) in bbcode)
	assert("快乐韭菜网" in bbcode)
	pass


func horizontal_rule_test() -> void:
	assert(MarkdownUtils.is_horizontal_rule_line("---"))
	assert(MarkdownUtils.is_horizontal_rule_line("- - -"))
	assert(not MarkdownUtils.is_horizontal_rule_line("-_*-"))
	var bbcode := MarkdownUtils.to_bbcode("---")
	assert(MarkdownUtils.format_horizontal_rule_line() in bbcode)
	assert("#" in MarkdownUtils.format_horizontal_rule_line())
	pass


func snake_case_underscore_test() -> void:
	var bbcode := MarkdownUtils.inline_to_bbcode("my_var_name stays plain")
	assert("[i]" not in bbcode)
	assert("my_var_name" in bbcode)
	pass


func bold_italic_triple_asterisk_test() -> void:
	var bbcode := MarkdownUtils.inline_to_bbcode("***both***")
	assert("[b][i]both[/i][/b]" in bbcode)
	pass


func bold_does_not_add_font_size_test() -> void:
	var bbcode := MarkdownUtils.inline_to_bbcode("**bold**")
	assert(bbcode == "[b]bold[/b]")
	pass


func blank_lines_preserved_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("para one\n\npara two")
	assert(bbcode == "para one\n\npara two")
	pass


func code_fence_blank_lines_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("```\nline1\n\nline2\n```")
	assert("[table=1]" in bbcode)
	assert("[/table]" in bbcode)
	assert("[cell shrink=false expand=1 bg=" in bbcode)
	assert("bg=" in bbcode)
	assert("[code]" in bbcode)
	assert("line1" in bbcode and "line2" in bbcode)
	pass


## The fence fill follows the theme accent instead of a hex the caller passes in.
func code_block_bg_themed_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("```\nx\n```")
	assert("bg=" + MarkdownUtils.to_bbcode_color(ColorMarkdown.code_block_bg) in bbcode)
	pass


func code_fence_right_gutter_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("```\nx\n```")
	assert(bbcode.begins_with("[table=1][cell padding=" + MarkdownUtils.CODE_BLOCK_RIGHT_GUTTER + "]"))
	assert(bbcode.ends_with("[/cell][/table]"))
	pass


func inline_code_tinted_test() -> void:
	var bbcode := MarkdownUtils.inline_to_bbcode("`x`")
	assert(bbcode.begins_with(MarkdownUtils.INLINE_CODE_MARGIN))
	assert(bbcode.ends_with(MarkdownUtils.INLINE_CODE_MARGIN))
	assert("[bgcolor=" + MarkdownUtils.to_bbcode_color(ColorMarkdown.inline_code_bg) + "]" in bbcode)
	assert("[code]x[/code]" in bbcode)
	assert("[table=" not in bbcode)
	pass


## The engine's default 3px highlight padding paints the chip over the line above and
## below it, so the box is pinned to the glyphs instead.
func inline_code_box_padding_test() -> void:
	var label := MarkdownUtils.create_rich_text_label(Color.WHITE, "`x`", true)
	assert(label.get_theme_constant("text_highlight_v_padding") == MarkdownUtils.HIGHLIGHT_V_PADDING)
	assert(label.get_theme_constant("text_highlight_h_padding") == MarkdownUtils.HIGHLIGHT_H_PADDING)
	label.free()
	pass


## A highlight over a bubble follows the theme color ([ThemeColorCard]) instead of the
## engine's default tint, and both label kinds share it.
func selection_theme_test() -> void:
	var labels: Array[RichTextLabel] = [
		MarkdownUtils.create_rich_text_label(Color.WHITE, "select me", true),
		MarkdownUtils.create_plain_rich_text_label(Color.WHITE),
	]
	for label: RichTextLabel in labels:
		assert(label.get_theme_color("selection_color") == ColorCard.selection_color)
		assert(label.get_theme_color("font_selected_color") == ColorCard.title_color)
		label.free()
	pass


func html_underline_test() -> void:
	var bbcode := MarkdownUtils.inline_to_bbcode("<u>图生图</u>, plain")
	assert(bbcode == "[u]图生图[/u], plain")
	assert("<u>" not in bbcode)
	pass


func brackets_escaped_test() -> void:
	var bbcode := MarkdownUtils.inline_to_bbcode("array[0]")
	assert(bbcode == "array[lb]0[rb]")
	assert("[lb[rb]" not in bbcode)
	pass


func inline_code_protects_markdown_test() -> void:
	var link_in_code := MarkdownUtils.inline_to_bbcode("`[text](url)`")
	assert("[code]" in link_in_code)
	assert("[url=" not in link_in_code)
	assert("[lb]text[rb](url)" in link_in_code)

	var bold_in_code := MarkdownUtils.inline_to_bbcode("`**x**`")
	assert("[code]" in bold_in_code)
	assert("[b]" not in bold_in_code)
	assert("**x**" in bold_in_code)
	pass


func dunder_not_bold_test() -> void:
	var bbcode := MarkdownUtils.inline_to_bbcode("call __init__ now")
	assert("__init__" in bbcode)
	assert("[b]" not in bbcode)
	assert("[i]" not in bbcode)
	pass


func nested_emphasis_test() -> void:
	var bold_italic := MarkdownUtils.inline_to_bbcode("**foo *bar* baz**")
	assert(bold_italic == "[b]foo [i]bar[/i] baz[/b]")
	var italic_bold := MarkdownUtils.inline_to_bbcode("*foo **bar** baz*")
	assert(italic_bold == "[i]foo [b]bar[/b] baz[/i]")
	pass


func link_title_stripped_test() -> void:
	var bbcode := MarkdownUtils.inline_to_bbcode("[hi](https://a.com \"t\")")
	assert("[url=https://a.com]" in bbcode)
	assert("[url]hi[/url]" not in bbcode)
	assert("hi" in bbcode)
	assert("\"t\"" not in bbcode)
	pass


func url_with_parens_test() -> void:
	var bbcode := MarkdownUtils.inline_to_bbcode("[w](https://en.wikipedia.org/wiki/Foo_(bar))")
	assert("Foo_(bar)" in bbcode)
	assert("[url=https://en.wikipedia.org/wiki/Foo_(bar)]" in bbcode)
	pass


func link_label_blue_test() -> void:
	var bbcode := MarkdownUtils.inline_to_bbcode("[hi](https://a.com)")
	assert(
			bbcode == "[url=https://a.com][color=%s]hi[/color][/url]" % MarkdownUtils.to_bbcode_color(ColorMarkdown.link_color)
	)
	var bold_label := MarkdownUtils.inline_to_bbcode("[**hi**](https://a.com)")
	assert("[b]hi[/b]" in bold_label)
	assert("[/color][/url]" in bold_label)
	pass


func crlf_normalized_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("# Title\r\n\r\n**bold**")
	assert("[font_size=32]" in bbcode)
	assert("[b]bold[/b]" in bbcode)
	assert("\r" not in bbcode)
	pass


func tilde_fence_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("~~~\ncode\n~~~")
	assert("[code]" in bbcode)
	assert("code" in bbcode)
	pass


func heading_trailing_hashes_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("# Title ##")
	assert("[font_size=32]" in bbcode)
	assert("Title" in bbcode)
	assert("##" not in bbcode)
	pass


func indented_heading_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("  # Title")
	assert("[font_size=32]" in bbcode)
	assert("Title" in bbcode)
	pass


func ordered_paren_list_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("1) first")
	assert("1. first" in bbcode)
	pass


func literal_bbcode_tag_escaped_test() -> void:
	assert(MarkdownUtils.inline_to_bbcode("press [b] to bold") == "press [lb]b[rb] to bold")
	assert(MarkdownUtils.inline_to_bbcode("the [/code] tag") == "the [lb]/code[rb] tag")
	assert(MarkdownUtils.inline_to_bbcode("[lb]") == "[lb]lb[rb]")
	assert(
			MarkdownUtils.inline_to_bbcode("[url=https://a.com]x[/url]")
			== "[lb]url=https://a.com[rb]x[lb]/url[rb]"
	)
	pass


func brackets_inside_emphasis_escaped_test() -> void:
	assert(MarkdownUtils.inline_to_bbcode("**a[0]b**") == "[b]a[lb]0[rb]b[/b]")
	assert(MarkdownUtils.inline_to_bbcode("**[b]**") == "[b][lb]b[rb][/b]")
	assert(MarkdownUtils.inline_to_bbcode("*[i]*") == "[i][lb]i[rb][/i]")
	pass


func literal_tag_in_block_escaped_test() -> void:
	assert(MarkdownUtils.to_bbcode("- use [i] for italic") == "• use [lb]i[rb] for italic")
	assert("[lb]center[rb]" in MarkdownUtils.to_bbcode("# [center] title"))
	pass


func spaced_markers_stay_plain_test() -> void:
	var stars := MarkdownUtils.inline_to_bbcode("3 * 4 * 5")
	assert("[i]" not in stars)
	assert(stars == "3 * 4 * 5")
	var unders := MarkdownUtils.inline_to_bbcode("a _ b _ c")
	assert("[i]" not in unders)
	assert(unders == "a _ b _ c")
	pass


func gfm_table_test() -> void:
	var md := "| 时段 | 天气 | 气温 |\n|---|---|---|\n| 12–13时 | 多云 | ~30℃ |\n| 14–16时 | 阴 | 29~30℃ |"
	var bbcode := MarkdownUtils.to_bbcode(md)
	assert("[table=3]" in bbcode)
	assert("[/table]" in bbcode)
	assert("border=" in bbcode)
	assert(bbcode.count("[/cell]") == 9)
	assert("[b]时段[/b]" in bbcode)
	assert("[b]天气[/b]" in bbcode)
	assert("12–13时" in bbcode)
	assert("29~30℃" in bbcode)
	assert("| 时段 |" not in bbcode)
	pass


func table_inline_in_cell_test() -> void:
	var md := "| name | val |\n|---|---|\n| **x** | *y* |"
	var bbcode := MarkdownUtils.to_bbcode(md)
	assert("[b]name[/b]" in bbcode)
	assert("[b]x[/b]" in bbcode)
	assert("[i]y[/i]" in bbcode)
	pass


func pipe_without_separator_stays_plain_test() -> void:
	var bbcode := MarkdownUtils.to_bbcode("a | b\nc | d")
	assert("[table=" not in bbcode)
	assert("a | b" in bbcode)
	pass


## Bubble labels clear their highlight on a press outside them — a click on the
## (non-focusable) chat background never moves focus, so the built-in focus-loss path
## leaves the highlight behind.
func click_outside_clears_selection_test() -> void:
	var host := Control.new()
	host.size = Vector2(400, 400)
	gdf.gdf_node.add_child(host)

	var label := MarkdownUtils.create_rich_text_label(Color.WHITE, "select me", true)
	label.position = Vector2(10, 10)
	label.size = Vector2(200, 60)
	host.add_child(label)

	var viewport := host.get_viewport()
	await viewport.get_tree().process_frame
	assert(not label.is_processing_input())

	send_mouse_press(viewport, Vector2(20, 20))
	label.select_all()
	assert(label.get_selected_text() == "select me")
	assert(label.is_processing_input())

	send_mouse_press(viewport, Vector2(350, 350))
	assert(label.get_selected_text() == StringUtils.EMPTY)
	assert(not label.is_processing_input())

	host.queue_free()
	pass


func send_mouse_press(viewport: Viewport, position: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = position
		event.global_position = position
		viewport.push_input(event, true)
	pass
