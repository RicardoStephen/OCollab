
open Patch

let _ =
  Js.Unsafe.global##jsooEditor <- jsobject
    method editor_apply_patch jsdoc jspatch =
      Js.string (apply_patch (Js.to_string jsdoc)
        (patch_of_string (Js.to_string jspatch)))
  end

