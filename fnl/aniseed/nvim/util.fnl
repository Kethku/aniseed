(module aniseed.nvim.util
  {autoload {nvim aniseed.nvim}})

(defn normal [keys]
  "Execute some command as if you were in normal mode silently."
  (nvim.ex.silent (.. "exe \"normal! " keys "\"")))

(defn fn-bridge [viml-name mod lua-name opts]
  "Creates a VimL function that calls through to a Lua function in the named
  module. Takes an optional opts table, if that contains `:range true` it'll
  plumb the range start and end into the function call's first two arguments.
  Will return the result from the VimL function by default, this can be turned
  off by setting `:return false` in the opts table."
  (let [{:range range
         :return return}
        (or opts {})]
    (nvim.ex.function_
      (.. viml-name
          "(...)" 
          (if range
            " range"
            "")
          "
          "
          (if (not= return false)
            :return
            :call)
          " luaeval(\"require('" mod "')['" lua-name "']("
          (if range
            "\" . a:firstline . \", \" . a:lastline . \", "
            "")
          "unpack(_A))\", a:000)
          endfunction"))))

(defn with-out-str [f]
  "Capture all print output and return it."
  (nvim.ex.redir "=> g:aniseed_nvim_util_out_str")
  (let [(ok? err) (pcall f)]
    (nvim.ex.redir "END")

    ;; This prevents the echoed messages appearing at the bottom.
    (nvim.ex.echon "")
    (nvim.ex.redraw)

    (when (not ok?)
      (error err)))

  (string.gsub
    nvim.g.aniseed_nvim_util_out_str
    "^(\n?)(.*)$" "%2%1"))
