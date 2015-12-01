module Html = Dom_html

let docid = 
  let search = Dom_html.window##location##search in
  search##slice_end(4)

let set_full_doc mirror = 
  let req = XmlHttpRequest.create () in
  let f () =
    match (req##readyState, req##status) with
    | (XmlHttpRequest.DONE, 200) ->
       Js.Unsafe.meth_call mirror "setValue" (Array.make 1 (Js.Unsafe.inject (req##responseText)))
    | _ -> () in
  req##onreadystatechange <- (Js.wrap_callback f);
  req##_open(Js.string "GET",
             (Js.string ("/get_doc_text?id="))##concat(docid),
             Js._true);
  req##send(Js.null);
  ()
         

let start _ =
  let body = Js.Unsafe.inject Html.window##document##body in
  let obj = Js.Unsafe.meth_call Js.Unsafe.global "CodeMirror" (Array.make 1 body) in
  set_full_doc obj;
  Js._false

let _ = Html.window##onload <- Html.handler start
