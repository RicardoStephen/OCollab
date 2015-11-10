(* sending receiving things from server
handling events like insertion/deletion on document
 *)

(*stuff on the document*)
(*Need to specify position. Should these return patch? or a pair of document and patch?*)
val delete_text : document -> (*position?*) -> document * patch
val insert_text : document -> (*position?*) -> document * patch


(*Don't need. THis is taken care of in document.ml*)
val change_title : doc_id


(* maintaining current list of patches and merging with the server regularly *)
val patches_to_server : (*might not need this, since it will just use current_patches_list*)patch list ->

val current_patches_list : patch list


