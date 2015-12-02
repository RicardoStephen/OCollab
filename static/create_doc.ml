module Html = Dom_html

let create_form _ = 
  let d = Html.window##document in
  let body = d##body in
(*  let body = Js.Unsafe.inject d##body in*)
  let textinput = Html.createInput ~_type:(Js.string "text") d in
  textinput##defaultValue <- Js.string ("Document Name");
  textinput##size <- 20;
  let submitbutton = Html.createButton ~_type:(Js.string "button") d in (* "Create"*)  (*~name:(Js.string "Create") in *)
  submitbutton##innerHTML <- (Js.string "Create");
  submitbutton##value <- (Js.string "Create");
  submitbutton##disabled <- Js._false;
  submitbutton##tabIndex <- 5;
  submitbutton##onclick <- Html.handler
    (fun _ ->
       let value = textinput##value in
       let req = XmlHttpRequest.create () in
       let f () = 
         match (req##readyState, req##status) with
         | (XmlHttpRequest.DONE, 200) ->
            let anchor = Html.createA d in
            anchor##href <- (Js.string ("/doc?id="))##concat(req##responseText);
            anchor##innerHTML <- (Js.string "Click here to access your document");
            Dom.appendChild body anchor; 
         | _ -> () in
       let callback = Js.wrap_callback f in
       req##onreadystatechange <- callback;
       req##_open(Js.string "GET", 
                 (Js.string ("/create_doc?title="))##concat(Js.encodeURI value),
                 Js._true);
       req##send(Js.null);
       Js._false
    );
  Dom.appendChild body textinput;
  Dom.appendChild body submitbutton;
(*   Dom.appendChild body div; *)
  Js._false

let _ = Html.window##onload <- Html.handler create_form
                      


                        
                              
