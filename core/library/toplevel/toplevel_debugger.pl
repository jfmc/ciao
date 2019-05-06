% ---------------------------------------------------------------------------
% Debug mode per module/file

:- use_module(library(aggregates), [findall/3]).

:- if(defined(optim_comp)).

:- use_module(engine(rt_exp), [current_module/1, '$user_module_id'/1]).
:- use_module(compiler(store), [spec_to_key/2]).

% Module options
% TODO: currently only used for debugging
% TODO: create an equivalent predicate in comp (or ciaoc) to pass options
:- include(compiler(options__interface)).
module__options(Spec, Module, Opts) :-
	'$user_module_id'(Module),
	!,
	module__options(Spec, user, Opts).
module__options(Spec, _, Opts) :-
	spec_to_key(Spec, Key),
	interpret_speckey(Key),
	!,
	debug_opts(debug_raw, Opts).
module__options(_, Module, Opts) :-
	interpret_module(Module, Mode),
	!,
	( Mode = srcdbg ->
	    debug_opts(debug_srcdbg, Opts)
	; debug_opts(debug_raw, Opts)
	).

debug_opts(M, [(:- use_package(library(debugger/M)))]).

:- pred interpret_module(Module, Mode). % where Mode is srcdbg or raw
:- data interpret_module/2.
:- pred interpret_speckey(SpecKey). % (mode is always raw)
:- data interpret_speckey/1.

current_source_debugged(Ss) :- 
	findall(S, current_fact(interpret_module(S, srcdbg)), Ss).

:- export(set_debug_mode/1).
set_debug_mode(Spec) :-
	spec_to_key(Spec, Key),
	retractall_fact(interpret_speckey(Key)),
	assertz_fact(interpret_speckey(Key)).

:- export(set_nodebug_mode/1).
set_nodebug_mode(Spec) :-
	spec_to_key(Spec, Key),
	retractall_fact(interpret_speckey(Key)).

:- multifile '$mod_srcdbg'/1. % generated by $insert_debug_info declaration

needs_reloading(M, DebugMode) :-
	current_module(M), !,
	%DebugMode0 = ( '$mod_srcdbg'(M) ? srcdbg | raw ), % TODO: defined(optim_comp)
	( '$mod_srcdbg'(M) -> DebugMode0 = srcdbg ; DebugMode0 = raw ),
	DebugMode \== DebugMode0.

:- export(set_debug_module/1).
set_debug_module(Mod) :-
	retractall_fact(interpret_module(Mod, _)),
	assertz_fact(interpret_module(Mod, raw)).

:- export(set_debug_module_source/1).
set_debug_module_source(Mod) :-
	retractall_fact(interpret_module(Mod, _)),
	assertz_fact(interpret_module(Mod, srcdbg)).

:- export(set_nodebug_module/1).
set_nodebug_module(Mod) :-
	retractall_fact(interpret_module(Mod, _)).

:- else.

:- use_module(library(compiler),
	    [set_debug_mode/1, set_nodebug_mode/1, mode_of_module/2,
	     set_debug_module/1, set_nodebug_module/1,
	     set_debug_module_source/1]).
:- use_module(library(compiler/c_itf), [interpret_srcdbg/1]).

current_source_debugged(Ss) :-
	findall(S, current_fact(interpret_srcdbg(S)), Ss).

needs_reloading(M, DebugMode) :-
	mode_of_module(M, Mode), Mode \== interpreted(DebugMode).

:- endif.

% ---------------------------------------------------------------------------
% Debugger toplevel interface

:- use_module(library(lists), [difference/3]).
:- use_module(library(format), [format/3]).

:- export(consult/1).
consult([]) :- !.
consult([File|Files]) :- !,
	consult(File),
	consult(Files).
consult(File) :-
	set_debug_mode(File),
	ensure_loaded__2(File).

:- export(compile/1).
compile([]) :- !.
compile([File|Files]) :- !,
	compile(File),
	compile(Files).
compile(File) :-
	set_nodebug_mode(File),
	ensure_loaded__2(File).

:- export(debug_module/1).
:- redefining(debug_module/1).
debug_module(M) :-
	set_debug_module(M),
	debugger:debug_module(M),
	( needs_reloading(M, raw) ->
	    message(user, ['{Consider reloading module ', M, '}'])
	; true
	),
	display_debugged.

:- export(nodebug_module/1).
:- redefining(nodebug_module/1).
nodebug_module(M) :-
	set_nodebug_module(M),
	debugger:nodebug_module(M),
	display_debugged.

:- export(debug_module_source/1).
:- redefining(debug_module_source/1).
debug_module_source(M) :-
	set_debug_module_source(M),
	debugger:debug_module_source(M),
	( needs_reloading(M, srcdbg) ->
	    message(user, ['{Consider reloading module ', M, '}'])
	; true
	),
	display_debugged.

:- export(display_debugged/0).
display_debugged :-
	current_debugged(Ms),
	current_source_debugged(Ss),
	difference(Ms, Ss, M),
	( M = [] ->
	    format(user, '{No module is selected for debugging}~n', [])
	; format(user, '{Modules selected for debugging: ~w}~n', [M])
	),
	( Ss = [] ->
	    format(user, '{No module is selected for source debugging}~n', [])
	; format(user, '{Modules selected for source debugging: ~w}~n', [Ss])
	).
