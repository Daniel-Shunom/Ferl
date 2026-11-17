%%%-------------------------------------------------------------------
%% @doc ferl public API
%% @end
%%%-------------------------------------------------------------------

-module(ferl_app).

-behaviour(application).

-export([start/2, stop/1, do/1]).

-include_lib("inets/include/httpd.hrl").

start(_StartType, _StartArgs) ->
    {ok, HttpId} = inets:start(httpd, [
        {port, 8080},
        {server_name, "ferl_server"},
        {server_root, "/tmp/"},
        {document_root, "/tmp/"},
        {bind_address, "localhost"},
        {modules, [?MODULE]}
    ]),
    {ok, SupId} = ferl_sup:start_link(),
    {ok, SupId, HttpId}.

stop(HttpId) ->
    inets:stop(httpd, HttpId),
    ok.

do(ModData) ->
    case ModData#mod.request_uri of
        "/" ->
            Body = "<h1>Welcome to ferl server in erlang!</h1>",
            {proceed, [{response, {200, Body}}]};

        _ -> 
            Body = "<h1>Path not found!</h1>",
            {proceed, [{response, {404, Body}}]}
    end.
%% internal functions
