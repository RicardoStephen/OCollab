let start _ =
  let body = Js.Unsafe.inject Dom_html.window##document##body in
  let _ = Js.Unsafe.meth_call Js.Unsafe.global "CodeMirror" (Array.make 1 body)
  in Js._false

let _ = Dom_html.window##onload <- Dom_html.handler start
