extends Control

const ARTICLE := """# The Field Guide to Markdown Rendering

This long-form article exercises **MarkdownParser** and **MarkdownHelper** with realistic English prose, structured content, inline formatting, code, tables, links, and images. A dedicated Chinese section later in the article verifies CJK fonts, punctuation, wrapping, and mixed-language layout.

> Markdown is valuable because structure and meaning remain readable even before the document is rendered.
> This second quoted line checks consecutive blockquotes, indentation, color, and responsive wrapping.

---

## 1. Typography and Inline Styles

A normal paragraph should remain comfortable to read when the window becomes narrow. This sentence contains **bold text**, *italic text*, ***bold italic text***, ~~struck text~~, __underscore bold__, _underscore italic_, and the supported extension <u>HTML underline</u>.

Inline code such as `var message := "Hello, Markdown!"` should use a distinct background. Literal content inside code—`[b]`, `**asterisks**`, and `array[0]`—must not be parsed a second time.

External links should be clearly recognizable: visit [Godot Engine](https://godotengine.org), or test a formatted label with [**OpenAI**](https://openai.com "OpenAI").

### A Third-Level Heading

#### A Fourth-Level Heading

##### A Fifth-Level Heading

###### A Sixth-Level Heading

## 2. Lists and Tasks

- The first unordered item is intentionally short.
- The second item is long enough to wrap across multiple lines, making bullet alignment and continuation indentation easy to inspect.
* An asterisk can also introduce a list item.
+ A plus sign is accepted as another list marker.

1. Prepare the Markdown source.
2. Convert the source into RichTextLabel BBCode.
3) Render the result and inspect its visual hierarchy.

- [x] Headings and paragraphs
- [x] Emphasis, links, and inline code
- [x] Tables, quotes, and images
- [ ] Verify the layout at several window widths

## 3. Code Blocks

```gdscript
func greet(name: String) -> String:
    var message := "Hello, %s!" % name
    # Markdown stays literal here: **bold**, [link](url), and ---
    return message
```

The fenced block above should preserve indentation and spaces while presenting an independent background. The plain-text block below also contains a blank line:

~~~
Markdown -> Parser -> BBCode -> RichTextLabel

Blank lines must survive the conversion.
~~~

## 4. Feature Matrix

The first matrix covers inline syntax. It intentionally mixes plain text, nested formatting, punctuation, links, code, and CJK characters inside table cells.

| Inline feature | Markdown source | Rendered sample | What to inspect |
| :--- | :---: | :--- | ---: |
| Bold | `**strong**` | **strong** | Weight |
| Italic | `*emphasis*` | *emphasis* | Slant |
| Bold italic | `***both***` | ***both*** | Nested style |
| Underscore bold | `__strong__` | __strong__ | Alternate marker |
| Underscore italic | `_emphasis_` | _emphasis_ | Word boundaries |
| Strike | `~~obsolete~~` | ~~obsolete~~ | Strike line |
| HTML underline | `<u>underlined</u>` | <u>underlined</u> | Underline position |
| Inline code | `` `code()` `` | `code()` | Font and chip |
| Link | `[Godot](https://godotengine.org)` | [Godot](https://godotengine.org) | Color and click |
| Formatted link | `[**OpenAI**](https://openai.com)` | [**OpenAI**](https://openai.com) | Nested bold label |
| Literal brackets | `array[0]` | array[0] | No BBCode leak |
| Nested emphasis | `**outer *inner* text**` | **outer *inner* text** | Recursive styling |
| Dunder name | `__init__` | __init__ | No false bold |
| Chinese bold | `**中文粗体**` | **中文粗体** | CJK weight |
| Mixed language | `Godot 引擎 4.x` | Godot 引擎 4.x | Shared baseline |
| Empty cell | | Content after empty cell | Column normalization |

The second matrix records the block-level coverage provided by this article. The examples are descriptive because block constructs cannot be nested safely inside a table cell.

| Block feature | Source pattern | Demonstrated in | Visual expectation |
| :--- | :---: | :--- | ---: |
| Headings | `#` through `######` | Sections 1–7 | Clear size hierarchy |
| Paragraphs | Consecutive prose | Every section | Natural wrapping |
| Blockquotes | `> quoted line` | Introduction and edge cases | Accent bar and inset text |
| Unordered lists | `-`, `*`, `+` | Section 2 | Stable bullet alignment |
| Ordered lists | `1.` and `3)` | Section 2 | Preserved numbering |
| Task lists | `- [x]`, `- [ ]` | Sections 2 and 6 | Checked and empty boxes |
| Fenced code | Triple backticks | Section 3 | Preserved whitespace |
| Tilde fence | Triple tildes | Section 3 | Same code treatment |
| Tables | Header separator row | Section 4 and 6 | Grid, padding, header fill |
| Horizontal rules | `---`, `* * *`, `___` | Sections 7 and conclusion | Full-width divider |
| Images | `![alt](path)` | Section 5 | Aspect-safe scaling |

## 5. Image Gallery

The images in this section are read directly from `.ai/test/image`. The first PNG checks portrait scaling and fine visual detail.

![Portrait test image](C:/github/gai/.ai/test/image/girl.png)

### Armored Vehicle Series

These three JPEG files verify consecutive images, differing aspect ratios, scaling, captions, and spacing inside a long article.

![Tank test image one](res://.ai/test/image/tank1.jpg)

![Tank test image two](res://.ai/test/image/tank2.jpg)

![Tank test image three](res://.ai/test/image/tank3.jpg)

## 6. 中文排版测试

这一节专门检查中文 Markdown 的显示效果。中文正文应使用正确的字体，标点符号应该清晰，窗口变窄时需要自然换行，不能出现字符缺失或异常间距。

这里包含 **中文粗体**、*中文斜体*、***粗斜体组合***、~~中文删除线~~、<u>中文下划线</u>，以及行内代码 `打印("你好，世界！")`。

> **中文组合引用：** 引用内部包含粗体、*斜体*、`代码片段` 和 [中文链接](https://example.com)。这一行写得稍长，用于观察中文连续文本在引用区域内的自动换行。

- 第一项：检查项目符号与中文基线
- 第二项：检查较长的中文列表内容换行之后，后续文字是否与首行内容保持正确对齐
- [x] 中文标题、正文和引用
- [ ] 中文与 English 混排效果

| 检查项目 | 示例内容 | 预期结果 |
| :--- | :---: | ---: |
| 字体 | 中文字符 ABC 123 | 字形完整 |
| 标点 | “引号”、句号。 | 间距自然 |
| 混排 | Godot 引擎 4.x | 基线一致 |

## 7. Edge Cases

The following expressions should remain ordinary text rather than accidental formatting: `my_var_name`, 3 * 4 * 5, a _ b _ c, test@example.com, and the literal tag `[center]`.

Raw RichTextLabel tags must be escaped rather than executed: [b]not bold[/b], [/code], and [url=https://example.com]not a live BBCode link[/url].

These links exercise destination parsing: [a URL with parentheses](https://en.wikipedia.org/wiki/Markdown_(markup)), [an angle-bracket destination](<https://example.com/docs>), [a double-quoted title](https://example.com "Example title"), and [a single-quoted title](https://example.com 'Another title').

  ### An Indented Heading

### A Heading with Closing Hashes ###

The next two lines contain pipes but no separator row, so they must remain ordinary paragraphs rather than becoming a table:

alpha | beta
gamma | delta

### Horizontal Rule Variants

Three hyphens:

---

Three spaced asterisks:

* * *

Three underscores:

___

> **Combined English quote:** A blockquote may contain bold text, *emphasis*, `code`, and a [link](https://example.com) without losing its structure.

---

## Conclusion

The visual review passes when heading hierarchy, inline styles, lists, task boxes, code blocks, tables, links, Chinese text, all four images, scrolling, and text selection render correctly.
"""

@onready var background: ColorRect = $Background
@onready var page_margin: MarginContainer = $ContentScroll/PageMargin
@onready var article_body: VBoxContainer = $ContentScroll/PageMargin/ArticleBody


func _ready() -> void:
	background.color = ColorBase.app_background
	page_margin.add_theme_constant_override("margin_left", Margin.ma_12)
	page_margin.add_theme_constant_override("margin_top", Margin.ma_8)
	page_margin.add_theme_constant_override("margin_right", Margin.ma_12)
	page_margin.add_theme_constant_override("margin_bottom", Margin.ma_12)
	article_body.add_theme_constant_override("separation", Margin.ma_4)
	render_article()
	gdf.events.test_passed.emit()
	pass


func render_article() -> void:
	var markdown_lines: PackedStringArray = []
	for line: String in ARTICLE.split("\n"):
		if is_image_line(line):
			flush_markdown(markdown_lines)
			add_article_image(image_alt(line), image_path(line))
		else:
			markdown_lines.append(line)
	flush_markdown(markdown_lines)
	pass


func flush_markdown(lines: PackedStringArray) -> void:
	if lines.is_empty():
		return
	var markdown := "\n".join(lines).strip_edges()
	lines.clear()
	if markdown.is_empty():
		return
	article_body.add_child(MarkdownHelper.create_rich_text_label(ColorBase.primary_text, markdown, true))
	pass


func add_article_image(alt_text: String, resource_path: String) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(resource_path))
	if image == null or image.is_empty():
		var error_label := MarkdownHelper.create_plain_rich_text_label(ColorBase.error)
		error_label.text = "图片加载失败：%s" % resource_path
		article_body.add_child(error_label)
		return
	var texture := ImageTexture.create_from_image(image)
	var image_view := TextureRect.new()
	image_view.texture = texture
	image_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image_view.custom_minimum_size = Vector2(0, clampf(760.0 * image.get_height() / image.get_width(), 220.0, 560.0))
	image_view.tooltip_text = "%s\n%s" % [alt_text, resource_path]
	article_body.add_child(image_view)
	var caption := MarkdownHelper.create_rich_text_label(ColorBase.secondary_text, "*%s* — `%s`" % [alt_text, resource_path], true)
	article_body.add_child(caption)
	pass


func is_image_line(line: String) -> bool:
	var trimmed := line.strip_edges()
	return trimmed.begins_with("![") and trimmed.ends_with(")") and trimmed.contains("](")


func image_alt(line: String) -> String:
	var trimmed := line.strip_edges()
	var path_marker := trimmed.find("](")
	return trimmed.substr(2, path_marker - 2)


func image_path(line: String) -> String:
	var trimmed := line.strip_edges()
	var path_marker := trimmed.find("](")
	return trimmed.substr(path_marker + 2, trimmed.length() - path_marker - 3)
