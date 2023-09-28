-- cite style constants
local kBibStyleDefault = 'harvard'
local kBibStyles = { 'harvard', 'vancouver' }
local kBibStyleHarvard = 'Frontiers-Harvard'
local kBibStyleVancouver = 'Frontiers-Vancouver'
local kBibStyleUnknown = kBibStyleHarvard

-- layout and style
local kFormatting = pandoc.List({ 'preprint', 'review', 'doubleblind' })
local kLayouts = pandoc.List({ 'harvard', 'vancouver' })


local function setBibStyle(meta, style)
  if meta['biblio-style'] == nil then
    meta['biblio-style'] = style
    quarto.doc.add_format_resource('bib/' .. style .. '.bst')
  end
end

local function hasClassOption(meta, option)
  if meta['classoption'] == nil then
    return false
  end

  for i, v in ipairs(meta['classoption']) do
    if v[1].text == option then
      return true
    end
  end
  return false
end

local function addClassOption(meta, option)
  if meta['classoption'] == nil then
    meta['classoption'] = pandoc.List({})
  end

  if not hasClassOption(meta, option) then
    meta['classoption']:insert({ pandoc.Str(option) })
  end
end

local function printList(list)
  local result = ''
  local sep = ''
  for i, v in ipairs(list) do
    result = result .. sep .. v
    sep = ', '
  end
  return result
end

local bibstyle = kBibStyleDefault

return {
  {
    Meta = function(meta)
      -- If citeproc is being used, switch to the proper
      -- CSL file
      if quarto.doc.cite_method() == 'citeproc' and meta['csl'] == nil then
        meta['csl'] = quarto.utils.resolve_path('bib/Frontiers-Harvard.csl')
      end

      if quarto.doc.is_format("pdf") then

        -- read the journal settings
        local journal = meta['journal']
        local citestyle = nil
        local formatting = nil
        local layout = nil
        local name = nil

        if journal ~= nil then
          citestyle = journal['cite-style']
          formatting = journal['formatting']
          layout = journal['layout']
          name = journal['name']
        end

        -- process the site style
        if citestyle ~= nil then
          citestyle = pandoc.utils.stringify(citestyle)
        else
          citestyle = kBibStyleDefault
        end

        -- capture the bibstyle
        bibstyle = citestyle
        if citestyle == 'harvard' then
          setBibStyle(meta, kBibStyleHarvard)
          addClassOption(meta, 'harvard')
        elseif citestyle == 'vancouver' then
          setBibStyle(meta, kBibStyleVancouver)
          addClassOption(meta, 'vancouver')
        else
          error("Unknown journal cite-style " .. citestyle .. "\nPlease use one of " .. printList(kBibStyles))
          setBibStyle(meta, kBibStyleUnknown)
        end

        -- process the layout
        if formatting ~= nil then
          formatting = pandoc.utils.stringify(formatting)
          if kFormatting:includes(formatting) then
            addClassOption(meta, formatting)
          else
            error("Unknown journal formatting " .. formatting .. "\nPlease use one of " .. printList(kFormatting))
          end
        end

        -- process the type
        if layout ~= nil then
          layout = pandoc.utils.stringify(layout)
          if kLayouts:includes(layout) then
            addClassOption(meta, layout)
          else
            error("Unknown journal layout " .. layout .. "\nPlease use one of " .. printList(kLayouts))
          end
        end

        -- process the name
        if name ~= nil then
          name = pandoc.utils.stringify(name)
          quarto.doc.include_text('in-header', '\\journal{' .. name .. '}')
        end
      end

      return meta
    end
  },
  {
    Cite = function(cite)
      if bibstyle == 'number' then
        -- If we are numbered, force citations into normal mode
        -- as the author styles don't make sense
        for i, v in ipairs(cite.citations) do
          v.mode = 'NormalCitation'
        end
        return cite
      end
    end,

  }
}
