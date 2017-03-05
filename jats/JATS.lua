-- This is a JATS custom writer for pandoc.  It produces output
-- that tries to conform to the JATS 1.0 specification
-- http://jats.nlm.nih.gov/archiving/tag-library/1.0/index.html
--
-- Invoke with: pandoc -t jats.lua
--
-- Note:  you need not have lua installed on your system to use this
-- custom writer.  However, if you do have lua installed, you can
-- use it to test changes to the script.  'lua JATS.lua' will
-- produce informative error messages if your code contains
-- syntax errors.
--
-- Released under the GPL, version 2 or greater. See LICENSE for more info.

-- Tables to store metadata, headers, sections, back sections, references, figures and footnotes
local meta = {}
local headers = {}
local sections = {}
local back = {}
local references = {}
local figures = {}

-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
-- This gives you a fragment.  You could use the metadata table to
-- fill variables in a custom lua template.  Or, pass `--template=...`
-- to pandoc, and pandoc will do the template processing as
-- usual.
function Doc(body, metadata, variables)
  meta = metadata or {}

  -- if document doesn't start with section, add top-level section without title
  if string.sub(body, 1, 6) ~= '</sec>' then
    body = Header(1, '') .. '\n' .. body
  end

  -- strip closing section tag from beginning, add to end of document
  body = string.sub(body, 7) .. '</sec>'

  -- parse sections, turn body into table of sections
  for lev, title, content in string.gmatch(body, '<sec.-lev="(.-)".->%s<title>(.-)</title>(.-)</sec>') do
    attr = section_helper(tonumber(lev), content, title)
  end

  body = xml('body', '\n' .. table.concat(sections, '\n') .. '\n')

  if #back > 0 then
    body = body .. '\n' .. xml('back', '\n' .. table.concat(back, '\n'))
  end

  return body
end

-- XML character entity escaping and unescaping
function escape(s)
  local map = { ['<'] = '&lt;',
                ['>'] = '&gt;',
                ['&'] = '&amp;',
                ['"'] = '&quot;',
                ['\'']= '&#39;' }
  return s:gsub("[<>&\"']", function(x) return map[x] end)
end

function unescape(s)
  local map = { ['&lt;'] = '<',
                ['&gt;'] = '>',
                ['&amp;'] = '&',
                ['&quot;'] = '"',
                ['&#39;']= '\'' }
  return s:gsub('(&(#?)([%d%a]+);)', function(x) return map[x] end)
end

-- Helper function to convert an attributes table into
-- a string that can be put into XML elements.
function attributes(attr)
  local attr_table = {}
  for x, y in pairsByKeys(attr) do
    if y and y ~= '' then
      table.insert(attr_table, string.format(' %s="%s"', x, escape(y)))
    end
  end
  return table.concat(attr_table)
end

-- sort table, so that attributes are in consistent order
function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

-- generic xml builder
function xml(tag, s, attr)
  attr = attr and attributes(attr) or ''
  s = s and '>' .. s .. '</' .. tag .. '>' or '/>'
  return '<' .. tag .. attr .. s
end

-- Flatten nested table, needed for nested YAML metadata['
-- We only flatten associative arrays and create composite key,
-- numbered arrays and flat tables are left intact.
-- We also convert all hyphens in keys to underscores,
-- so that they are proper variable names
function flatten_table(tbl)
  local result = {}

  local function flatten(tbl, key)
    for k, v in pairs(tbl) do
      if type(k) == 'number' and k > 0 and k <= #tbl then
        result[key] = tbl
        break
      else
        k = (key and key .. '-' or '') .. k
        if type(v) == 'table' then
          flatten(v, k)
        else
          result[k] = v
        end
      end
    end
  end

  flatten(tbl)
  return result
end

-- Read a file from the working directory and
-- return its contents (or nil if not found).
function read_file(name)
  local base, ext = name:match("([^%.]*)(.*)")
  local fname = base .. ext
  local file = io.open(fname, "r")
  if not file then return nil end
  return file:read("*all")
end

-- Parse YAML string and return table.
-- We only understand a subset.
function parse_yaml(s)
  local l = {}
  local c = {}
  local i = 0
  local k = nil

  -- patterns
  line_pattern = '(.-)\r?\n'
  config_pattern = '^(%s*)([%w%-]+):%s*(.-)$'

  -- First split string into lines
  local function lines(line)
    table.insert(l, line)
    return ""
  end

  lines((s:gsub(line_pattern, lines)))

  -- Then go over each line and check value and indentation
  for _, v in ipairs(l) do
    v:gsub(config_pattern, function(indent, tag, v)
      if (v == '') then
        i, k = string.len(indent), tag
        c[tag] = {}
      else
        -- check whether value is enclosed by brackets, i.e. an array
        if v:find('^%[(.-)%]$') then
          arr = {};
          for match in (v:sub(2, -2) .. ','):gmatch('(.-)' .. ',%s*') do
              table.insert(arr, match);
          end
          v = arr;
        else
          -- if it is a string, remove optional enclosing quotes
          v = v:match('^["\']*(.-)["\']*$')
        end

        if string.len(indent) == i + 2 and k then
          c[k][tag] = v
        else
          c[tag] = v
        end
      end
    end)
  end

  return c
end

-- add appropriate sec-type attribute
function sec_type_helper(s)
  local map = { ['Abstract']= 'abstract',
                ['Acknowledgments']= 'acknowledgements',
                ['Author Summary']= 'author-summary',
                ['Conclusions'] = 'conclusions',
                ['Discussion'] = 'discussion',
                ['Glossary'] = 'glossary',
                ['Introduction'] = 'intro',
                ['Materials and Methods'] = 'materials|methods',
                ['Notes'] = 'notes',
                ['References']= 'references',
                ['Results']= 'results',
                ['Supporting Information']= 'supplementary-material',
                ['Supplementary Information']= 'supplementary-material' }
  return map[s]
end

function section_helper(lev, s, title)
  local attr = { ['sec-type'] = sec_type_helper(title) }

  if attr['sec-type'] == "acknowledgements" then
    table.insert(back, Ack(s, title))
  elseif attr['sec-type'] == "references" then
    table.insert(back, RefList(s, title))
  elseif attr['sec-type'] == "notes" then
    table.insert(back, Note(s, title))
  elseif attr['sec-type'] == "glossary" then
    table.insert(back, Glossary(s, title))
  elseif attr['sec-type'] == "abstract" or attr['sec-type'] == "author-summary" then
    -- discard, should be provided via metadata
  elseif attr['sec-type'] == "supplementary-material" then
    table.insert(sections, SupplementaryMaterial(s, title))
  else
    table.insert(sections, Section(lev, s, title, attr))
  end

  return attr
end

-- Create table with year, month, day and iso8601-formatted date
-- Input is iso8601-formatted date as string
-- Return nil if input is not a valid date
function date_helper(iso_date)
  if not iso_date or string.len(iso_date) ~= 10 then return nil end

  _,_,y,m,d = string.find(iso_date, '(%d+)-(%d+)-(%d+)')
  time = os.time({ year = y, month = m, day = d })
  date = os.date('*t', time)
  date.iso8601 = string.format('%04d-%02d-%02d', date.year, date.month, date.day)
  return date
end

-- Create affiliation table, linked to authors via aff-id
function affiliation_helper(tbl)

  set = {}
  i = 0
  for _,author in ipairs(tbl.author) do
    if author.affiliation then
      if not set[author.affiliation] then
        i = i + 1
        set[author.affiliation] = i
      end
      author['aff-id'] = set[author.affiliation]
    end
  end

  tbl.aff = {}
  for k,v in pairs(set) do
    aff = { id = v, name = k }
    table.insert(tbl.aff, aff)
  end

  return tbl
end

-- Create corresponding author table, linked to authors via cor-id
function corresp_helper(tbl)

  set = {}
  i = 0
  for _,author in ipairs(tbl.author) do
    if author.corresp and author.email then
      i = i + 1
      set[i] = author.email
      author['cor-id'] = i
    end
  end

  tbl.corresp = {}
  for k,v in pairs(set) do
    corresp = { id = k, email = v }
    table.insert(tbl.corresp, corresp)
  end

  return tbl
end

-- temporary fix
function fix_citeproc(s)
  s = s:gsub('</surname>, ', '</surname>')
  s = s:gsub('</name></name><name>','</name>')
  return s
end

-- Convert pandoc alignment to something HTML can use.
-- align is AlignLeft, AlignRight, AlignCenter, or AlignDefault.
function html_align(align)
  local map = { ['AlignRight']= 'right',
                ['AlignCenter']= 'center' }
  return map[align] or 'left'
end

-- Blocksep is used to separate block elements.
function Blocksep()
  return "\n"
end

-- The functions that follow render corresponding pandoc elements.
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).
-- Comments indicate the types of other variables.
-- Defined at https://github.com/jgm/pandoc/blob/master/src/Text/Pandoc/Writers/Custom.hs

-- block elements

function Plain(s)
  return s
end

function Para(s)
  return xml('p', s)
end

function RawBlock(s)
  return xml('preformat', s)
end

-- JATS restricts use to inside table cells (<td> and <th>)
function HorizontalRule()
  return '<hr/>'
end

-- lev is an integer, the header level.
-- we can't use closing tags, as we don't know the end of the section
function Header(lev, s, attr)
  attr = attr or {}
  attr['lev'] = '' .. lev
  return '</sec>\n<sec' .. attributes(attr) .. '>\n' .. xml('title', s)
end

function Note(s)
  return s
end

function CodeBlock(s, attr)
  -- If code block has class 'dot', pipe the contents through dot
  -- and base64, and include the base64-encoded png as a data: URL.
  if attr.class and string.match(' ' .. attr.class .. ' ',' dot ') then
    local png = pipe("base64", pipe("dot -Tpng", s))
    return '<img src="data:image/png;base64,' .. png .. '"/>'
  -- otherwise treat as code (one could pipe through a highlighter)
  else
    return "<pre><code" .. attributes(attr) .. ">" .. escape(s) ..
           "</code></pre>"
  end
end

function BlockQuote(s)
  xml('boxed-text', s)
end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function Table(caption, aligns, widths, headers, rows)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  table.insert(buffer, '<table-wrap>')
  if caption ~= '' then
    -- if caption begins with <bold> text, make it the <title>
    caption = string.gsub('<p>' .. caption, "^<p><bold>(.-)</bold>%s", "<title>%1</title>\n<p>")
    add(xml('caption>', caption))
  end
  add("<table>")
  if widths and widths[1] ~= 0 then
    for _, w in pairs(widths) do
      add('<col width="' .. string.format("%d%%", w * 100) .. '" />')
    end
  end
  local header_row = {}
  local empty_header = true
  for i, h in pairs(headers) do
    local align = html_align(aligns[i])

    -- remove <p> tag
    h = h:gsub("^<p>(.-)</p>", "%1")

    table.insert(header_row,'<th align="' .. align .. '">' .. h .. '</th>')
    empty_header = empty_header and h == ""
  end
  if empty_header then
    head = ""
  else
    add('<tr>')
    for _,h in pairs(header_row) do
      add(h)
    end
    add('</tr>')
  end
  for _, row in pairs(rows) do
    add('<tr>')
    for i,c in pairs(row) do
      -- remove <p> tag
      c = c:gsub("^<p>(.-)</p>", "%1")
      add('<td align="' .. html_align(aligns[i]) .. '">' .. c .. '</td>')
    end
    add('</tr>')
  end
  add('</table>\n</table-wrap>')
  return table.concat(buffer,'\n')
end

function BulletList(items)
  local attr = { ['list-type'] = 'bullet' }
  return List(items, attr)
end

function OrderedList(items)
  local attr = { ['list-type'] = 'order' }
  return List(items, attr)
end

function List(items, attr)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, xml('list-item', item))
  end
  return xml('list', '\n' .. table.concat(buffer, '\n') .. '\n', attr)
end

-- Revisit association list StackValue instance.
-- items is a table of tables
function DefinitionList(items)
  local buffer = {}
  for _,item in pairs(items) do
    for k, v in pairs(item) do
      local term = xml('term', k)
      local def = xml('def', table.concat(v,'</def><def>'))
      table.insert(buffer, xml('def-item', term .. def))
    end
  end
  return xml('def-list', '\n' .. table.concat(buffer, '\n') .. '\n')
end

function Div(s, attr)
  return s
end

-- custom block elements for JATS

-- section is generated after header to allow reordering
function Section(lev, s, title, attr)
  local last = headers[#headers]
  local h = last and last.h or {}
  h[lev] = (h[lev] or 0) + 1
  for i = lev + 1, #headers do
    table.remove(h, i)
  end

  local header = { ['h'] = h,
                   ['title'] = title,
                   ['id'] = 'sec-' .. table.concat(h,'.'),
                   ['sec-type'] = attr['sec-type'] }

  table.insert(headers, header)

  attr = { ['id'] = header['id'], ['sec-type'] = header['sec-type'] }
  title = xml('title', title ~= '' and title or nil)
  return xml('sec', '\n' .. title .. s, attr)
end

function SupplementaryMaterial(s, title, attr)
  attr = {}
  title = xml('title', title)
  local caption = xml('caption', title .. s)
  return xml('supplementary-material', '\n' .. caption .. '\n', attr)
end

function Ack(s, title)
  title = title and '\n' .. xml('title', title) or ''
  return xml('ack', title .. s)
end

function Glossary(s, title, attr)
  title = xml('title', title)
  return xml('glossary', title .. s, attr)
end

function RefList(s, title)
  s = fix_citeproc(s)

  -- format ids
  s = string.gsub(s, '<ref id="(%d+)">', function (r)
        local attr = { ['id'] = string.format('r%03d', tonumber(r)) }
        return '<ref ' .. attributes(attr) .. '>'
      end)

  for ref in string.gmatch(s, '(<ref.-</ref>)') do
    Ref(ref)
  end

  if #references > 0 then
    title = xml('title', title)
    return xml('ref-list', title .. table.concat(references, '\n'), attr)
  else
    return ''
  end
end

function Ref(s)
  table.insert(references, s)
  return #references
end

-- inline elements

function Str(s)
  return s
end

function Space()
  return ' '
end

function SoftBreak()
  return ''
end

function Emph(s)
  return xml('italic', s)
end

function Strong(s)
  return xml('bold', s)
end

function Strikeout(s)
  return xml('strike', s)
end

function Superscript(s)
  return xml('sup', s)
end

function Subscript(s)
  return xml('sub', s)
end

function SmallCaps(s)
  return xml('sc', s)
end

function SingleQuoted(s)
  return "'" .. s .. "'"
end

function DoubleQuoted(s)
  return '"' .. s .. '"'
end

-- format in-text citation
function Cite(s)
  local ids = {}
  for id in string.gmatch(s, '(%d+)') do
    id = tonumber(id)
    -- workaround to discard year mistakenly taken for key
    if id and id < 1000 then
      local attr = { ['ref-type'] = 'bibr',
                     ['rid'] = string.format("r%03d", id) }
      table.insert(ids, xml('xref', '[' .. id .. ']', attr))
    end
  end
  if #ids > 0 then
    return table.concat(ids)
  else
    -- return original key for backwards compatibility
    return s
  end
end

function Code(s, attr)
  return xml('preformat', s, attr)
end

function DisplayMath(s)
  return xml('disp-formula', s)
end

function InlineMath(s)
  return xml('inline-formula', s)
end

function RawInline(s)
  return xml('preformat', s)
end

function LineBreak()
  return ' '
end

function Link(s, src, title)
  if src ~= '' and s ~= '' then
    attr = { ['ext-link-type'] = 'uri',
             ['xlink:href'] = escape(src),
             ['xlink:title'] = escape(title),
             ['xlink:type'] = 'simple' }

    return xml('ext-link', s, attr)
  else
    return s
  end
end

function CaptionedImage(s, src, title)
  -- if title begins with <bold> text, make it the <title>
  title = string.gsub(title, "^<bold>(.-)</bold>%s", function(t) xml('title', t) end)
  local num = #figures + 1
  local attr = { ['id'] = string.format("g%03d", num) }
  local caption = xml('caption', s)
  local fig = xml('fig', caption .. Image(nil, src, title), attr)

  table.insert(figures, fig)
  return fig
end

function Image(s, src, title)
  local attr = { ['mimetype'] = 'image',
                 ['xlink:href'] = escape(src),
                 ['xlink:title'] = escape(title),
                 ['xlink:type'] = 'simple' }

  return xml('graphic', s, attr)
end

-- handle bold and italic
function Span(s, attr)
  if attr.style == "font-weight:bold" then
    return Strong(s)
  elseif attr.style == "font-style:italic" then
    return Emph(s)
  elseif attr.style == "font-variant: small-caps" then
    return SmallCaps(s)
  else
    return s
  end
end

-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
    return function() return "" end
  end
setmetatable(_G, meta)
