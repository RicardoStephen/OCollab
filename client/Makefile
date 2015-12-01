.PHONY: clean compile

compile:
	ocamlbuild -use-ocamlfind -plugin-tag "package(js_of_ocaml.ocamlbuild)" client.js

clean:
	@-rm -r _build
