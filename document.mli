
(*A document will have URL, text, patch, and a name associated with it.*)
type document

(*
 * Creates a new document with a particular name, and stores it within the filesystem.
 *)
val new_document : string -> document

(*
 * Allows user to modify the name of the document
 *)
val set_name : string -> document