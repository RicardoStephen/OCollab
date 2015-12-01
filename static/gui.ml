module Html = Dom_html

let start _ =
  let body = Js.Unsafe.inject Html.window##document##body in
  let obj = Js.Unsafe.meth_call Js.Unsafe.global "CodeMirror" (Array.make 1 body) in
  let _ = Js.Unsafe.meth_call obj "setValue" (Array.make 1 (Js.Unsafe.inject (Js.string "Hello world"))) in 
  Js._false

let _ = Html.window##onload <- Html.handler start


