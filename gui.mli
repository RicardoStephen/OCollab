
type position

(*Inserting or deleting text at certain position*)
val delete_text : document -> position -> document * patch
val insert_text : document -> position -> document * patch

(*Finding search phrase within a given document*)
val find : document -> string -> position

(* Sending patches to server*)
val patches_to_server : patch list -> unit

(* Not needed, done in document.mli
(* List of patches for the document *)
val current_patches_list : patch list
*)

(* Not needed, done with delete_text and insert_text
(* Add a patch to a document *)
val add_patch : patch list -> patch list
*)