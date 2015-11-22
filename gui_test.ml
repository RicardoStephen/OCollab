module Html = Dom_html

let start _ =
  let body = Js.Unsafe.inject Html.window##document##body in
  let _ = Js.Unsafe.meth_call Js.Unsafe.global "CodeMirror" (Array.make 1 body)
  in Js._false

let _ = Html.window##onload <- Html.handler start
