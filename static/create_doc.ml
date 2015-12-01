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
(*         | (XmlHttpRequest.DONE, 200) ->            *)
         | _ ->
            if(req##readyState <> XmlHttpRequest.DONE) then failwith "I was not ready" else
            let link = Html.createLink d in
            link##href <- (Js.string ("/doc?id="))##concat(req##responseText);
            link##charset <- (Js.string "Click here to access your document");
            Dom.appendChild body link;
            () in
(*         | (XmlHttpRequest.DONE, b) ->
            failwith ("Ricardo, "^(string_of_int b)^"status was returned")
         | (_, 200) ->
            failwith ("Ricardo, 200 status was returned, but there was another problem")
         | _ -> failwith "Ricardo, response problem" in *)
       let callback = Js.wrap_callback f in
       req##onreadystatechange <- callback;
       req##_open(Js.string "GET", 
                 (Js.string ("/create_doc?title="))##concat(value),
                 Js._true);
       req##send(Js.null);
       Js._false
    );
  Dom.appendChild body textinput;
  Dom.appendChild body submitbutton;
  Js._false

let _ = Html.window##onload <- Html.handler create_form
                      


                        
                              
