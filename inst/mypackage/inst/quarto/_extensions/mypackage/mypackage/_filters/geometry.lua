-- mypackage Quarto extension: dynamic geometry and class options
--
-- Mirrors inst/indiedown/pre_processor.R: when the document declares
-- `twocolumn: true` or `wide: true` in the YAML header, override geometry
-- with narrower margins and add `twocolumn` to classoption.

local function meta_is_true(value)
  if value == nil then return false end
  if value == true then return true end
  local s = pandoc.utils.stringify(value):lower()
  return s == "true" or s == "yes" or s == "on" or s == "1"
end

local function str_list(items)
  local result = pandoc.List({})
  for _, item in ipairs(items) do
    result:insert(pandoc.MetaInlines({ pandoc.Str(item) }))
  end
  return result
end

local function ensure_list(meta_value)
  if meta_value == nil then return pandoc.List({}) end
  if meta_value.t == "MetaList" then return meta_value end
  return pandoc.List({ meta_value })
end

local wide_geometry = {
  "top=1cm", "bottom=1.75cm",
  "left=2cm", "right=2cm",
  "includehead", "includefoot",
}

local default_geometry = {
  "top=2cm", "bottom=2cm",
  "left=2cm", "right=2cm",
}

function Meta(meta)
  local is_twocolumn = meta_is_true(meta.twocolumn)
  local is_wide = meta_is_true(meta.wide)

  if is_twocolumn then
    meta.classoption = ensure_list(meta.classoption)
    meta.classoption:insert(pandoc.MetaInlines({ pandoc.Str("twocolumn") }))
  end

  if meta.geometry == nil then
    if is_twocolumn or is_wide then
      meta.geometry = str_list(wide_geometry)
    else
      meta.geometry = str_list(default_geometry)
    end
  end

  return meta
end
