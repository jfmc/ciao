:- package(iso).
:- use_package(dcg).
%:- use_package('dcg/dcg_phrase').

:- use_module(library(aggregates)).
:- use_module(library(dynamic)).
:- use_module(library(iso_misc)).
:- use_module(library(iso_char)).
:- use_module(library(iso_incomplete)).
:- use_module(library(operators)).
:- use_module(library(read)).
:- use_module(library(write)).
:- use_module(library(terms_check), [subsumes_term/2]).
:- use_module(library(terms_vars), [term_variables/2]).
:- use_module(library(cyclic_terms), [acyclic_term/1]).

% TODO: refine? these were in old nonpure.pl
:- use_module(engine(io_basic)).
:- use_module(engine(prolog_flags)).
:- use_module(engine(stream_basic)).
:- use_module(engine(hiord_rt), [call/1]).
