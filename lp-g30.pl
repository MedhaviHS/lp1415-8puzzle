% ============================================================================ %
%          LOGICA PARA PROGRAMACAO - 2014/2015, 1o. ANO, 2o. SEMESTRE          %
% ============================================================================ %
%   Jogo do 8 | PROLOG - Realizado pelo grupo 30, constituido pelos alunos:    %
% - 78991: Ines Ferreira Guedes Duarte De Oliveira                             %
% - 81045: Rui Guilherme Cruz Ventura                                          %
% ============================================================================ %

% ====================== RESOLVES - Predicados Principais ======================

% resolve_manual/2 - resolve_manual(CI,CF) recebe a configuracao inicial do
% tabuleiro (CI) e, atraves de uma sequencia de comandos introduzidos pelo
% utilizador, pretende-se chegar a uma configuracao final/objectivo (CF)
resolve_manual(CI,CF) :-
    escreve_transformacao(CI,CF),
    pede_jogada(CI,CF), !.

% resolve_cego/2 - resolve_cego(CI,CF) recebe duas configuracoes, a do tabuleiro
% inicial (CI) e final/objectivo (CF), gerando movimentos possiveis e testando
% os varios, tentando resolver "as cegas"
resolve_cego(CI,CF) :-
    escreve_transformacao(CI,CF),
    resolve_cego(CI,CF,[CI],[]), !.
resolve_cego(C,C,_,J) :-
    inverte(J,R),
    escreve_jogadas(R).
resolve_cego(C1,C2,CS,J) :- 
    mov_legal(C1,M,P,CR),
    \+ membro(CR,CS), !,
    (   resolve_cego(CR,C2,[CR|CS],[(P,M)|J])
    ;   resolve_cego(C1,C2,[CR|CS],J)
    ).

% resolve_info_h/2 - resolve_info_h(CI,CF) recebe duas configuracoes e atraves
% da aplicacao do algoritmo A*, utilizando a heuristica de nome distancia de
% hamming, atinge a configuracao final no menor numero de movimentos possiveis
resolve_info_h(CI,CF) :-
    escreve_transformacao(CI,CF),
    hamming(CI,CF,F),
    resolve_info_h(CF,[no(CI,F,0,F,[])],[]), !.
resolve_info_h(CF,LA,LF) :-
    menor_f(LA,No),
    no_c(No,C),
    (   C \== CF,
    !,  remove(No,LA,LA1),
        expande(No,CF,LA1,[No|LF],Suc),
        junta_listas(Suc,LA1,LA2),
        resolve_info_h(CF,LA2,LF)
    ;   no_m(No,J),
        inverte(J,R),
        escreve_jogadas(R)
    ).

% ============================= Cre'dito adicional =============================

% transformacao_possivel/2 - transformacao_possivel(CI,CF) afirma que e possivel
% obter a configuracao CF atraves da configuracao CI verificando se o numero de
% inversoes de CI para CF e par
transformacao_possivel(CI,CF) :-
	inversoes(CI,CF,N), !,
	N mod 2 =:= 0.

% inversoes/3 - inversoes(C1,C2,N) afirma que N e o numero de inversoes que
% existe entre C1 e C2. Utilizando C2 como referencia (estado final/objectivo),
% compara o i-esimo elemento de C1 com os elementos de C2 a partir da posicao
% i + 1 da configuracao C2
inversoes(C1,[_|R2],N) :- inversoes(C1,R2,R2,N,0), !.
inversoes([_|R],[_|R2],[],N,I) :- inversoes(R,R2,R2,N,I).
inversoes([P|R1],C2,[S|R2],N,I) :-
	(	P =\= 0, S =\= 0,
	!,	(	P > S,
		!,	I1 is I + 1,
			inversoes([P|R1],C2,R2,N,I1)
        ;   inversoes([P|R1],C2,R2,N,I)
		)
	;	inversoes([P|R1],C2,R2,N,I)
	).
inversoes([_|[]],_,[],N,N).

% ================================= Auxiliares =================================

% --- RESOLVE_MANUAL ---

% pede_jogada/2 - pede_jogada(C1,C2) pede uma jogada ao utilizador e, com base
% na mesma, transforma, se possivel, o tabuleiro com a configuracao C1. Repete
% ate resultar num tabuleiro com a configuracao C2
pede_jogada(C,C) :- writeln('Parabens!').
pede_jogada(C1,C2) :-
    writeln('Qual o seu movimento?'),
    read(M),
    (   mov_legal(C1,M,_,R),
    !,  nl,escreve_configuracao(R),nl,
        pede_jogada(R,C2)
    ;   writeln('Movimento ilegal'),
        pede_jogada(C1,C2)
    ).

% --- RESOLVE_INFO_H ---

% expande/5 - expande(No,CF,LA,LF,Suc) afirma que Suc e a lista de nos
% sucessores resultantes da expansao do no No
expande(No,CF,LA,LF,Suc) :- expande(No,CF,LA,LF,Suc,[]), !.
expande(No,CF,LA,LF,Suc,Aux) :-
    no_c(No,C),
    no_m(No,J),
    no_g(No,G),
    G1 is G + 1,
    mov_legal(C,M,P,C1),
    hamming(C1,CF,H),
    F is G1 + H,
    No1 = no(C1,F,G1,H,[(P,M)|J]),
    \+ (membro(No1,Aux); membro(No1,LA); membro(No1,LF)), !,
    expande(No,CF,LA,LF,Suc,[No1|Aux]).
expande(_,_,_,_,Suc,Suc).

% menor_f/2 - menor_f(L,N) afirma que N e o No na lista L com o menor f (=g + h)
menor_f([No|R],N) :- no_f(No,F), menor_f(R,N,No,F).
menor_f([],N,N,_).
menor_f([N1|R],N,No,F) :-
    no_f(N1,F1),
    (   F1 < F,
    !,  menor_f(R,N,N1,F1)
    ;   menor_f(R,N,No,F)
    ).

% no_<prop>/2 - no_<prop>(N,X) afirma que X e a propriedade <prop> do no N
no_c(no(C,_,_,_,_),C).
no_f(no(_,F,_,_,_),F).
no_g(no(_,_,G,_,_),G).
no_m(no(_,_,_,_,M),M).

% hamming/3 - hamming(L1,L2,D) afirma que D e o numero de pecas fora de sitio
% em L1 relativamente a L2 (distancia de hamming)
hamming(L1,L2,D) :- hamming(L1,L2,D,0), !.
hamming([],[],D,D).
hamming([E|R1],[E|R2],D,A) :- hamming(R1,R2,D,A).
hamming([E1|R1],[_|R2],D,A) :-
    E1 =\= 0,
    A1 is A + 1,
    hamming(R1,R2,D,A1);
    hamming(R1,R2,D,A).

% --- TRANSVERSAIS ---

% mov_legal/4 - mov_legal(C1,M,P,C2) afirma que C2 e a configuracao que se obtem
% de C1, ao aplicar o movimento M sobre a peca P
mov_legal(C1,M,P,C2) :-
    indice_elemento(0,C1,I),
    (   I // 3 < 2, I1 is I + 3, M = c
    ;   I // 3 > 0, I1 is I - 3, M = b
    ;   I mod 3 < 2, I1 is I + 1, M = e
    ;   I mod 3 > 0, I1 is I - 1, M = d
    ),
    indice_elemento(P,C1,I1),
    troca_elemento(C1,P,0,C2).

% troca_elemento/3 - troca_elemento(L1,P,L2) afirma que L2 e a lista que se
% obtem de trocar o elemento P1 com o elemento P2 da lista L1
troca_elemento([],_,_,[]).
troca_elemento([E|R],P1,P2,[E1|R1]) :-
    (   E =:= P1, !, E1 is P2
    ;   E =:= P2, !, E1 is P1
    ;   E1 is E
    ),
    troca_elemento(R,P1,P2,R1).

% indice_elemento/3 - indice_elemento(E,L,I) afirma que I e o indice da primeira
% ocorrencia do elemento E na lista L
indice_elemento(E,[E|_],0).
indice_elemento(E,[_|R],I) :-
    indice_elemento(E,R,I1),
    I is I1 + 1.

% ================================== Escritas ==================================

% escreve_transformacao/2 - escreve_transformacao(C1,C2) escreve as
% configuracoes C1 e C2, representando a primeira (C1) a configuracao inicial e
% a segunda (C2) a final/objectivo
escreve_transformacao(C1,C2) :-
    writeln('Transformacao desejada:'),
    escreve_transformacao(C1,C2,0).
escreve_transformacao([],[],_).
escreve_transformacao([E1,E2,E3|R1],[F1,F2,F3|R2],A) :-
    escreve_linha([E1,E2,E3]),
    (   A =:= 1,
    !,  write(' -> ')
    ;   write('    ')
    ),
    A1 is A + 1,
    escreve_linha([F1,F2,F3]),nl,
    escreve_transformacao(R1,R2,A1).

% escreve_configuracao/1 - escreve_configuracao(C) escreve a configuracao de um
% tabuleiro com base na sua representacao (lista)
escreve_configuracao([]).
escreve_configuracao([E1,E2,E3|R]) :-
    escreve_linha([E1,E2,E3]),nl,
    escreve_configuracao(R).

% escreve_jogadas/1 - escreve_jogadas(L) escreve as jogadas efectuadas com base
% nos elementos da lista L, pressupondo-se que sao um par (Peca,Movimento)
escreve_jogadas([(P,M)|R]) :-
    write('mova a peca '),write(P),
    escreve_movimento(M),
    (   R == [],
    !,  writeln('.')
    ;   nl,
        escreve_jogadas(R)
    ).

% escreve_linha/1 - escreve_linha(L) escreve os elementos da lista L,
% substituindo zeros por espacos
escreve_linha([]).
escreve_linha([E|R]) :-
    write(' '),
    (   E =:= 0,
    !,  write(' ')
    ;   write(E)
    ),
    write(' '),
    escreve_linha(R).

% escreve_movimento/1 - escreve_movimento(M) escreve o movimento M por extenso
escreve_movimento(M) :-
    (   M == c, write(' para cima')
    ;   M == b, write(' para baixo')
    ;   M == e, write(' para a esquerda')
    ;   M == d, write(' para a direita')
    ), !.

% ============================ Utilitarios (Listas) ============================

%inverte/2 - inverte(L1,L2) afirma que L2 e a lista que se obtem de inverter a
% ordem de L1
inverte(L1,L2) :- inverte(L1,L2,[]).
inverte([],L,L).
inverte([E|L1],L2,Res) :- inverte(L1,L2,[E|Res]).

% junta_listas/3 - junta_listas(L1,L2,L3) afirma que a lista L3 resulta de
% concatenar as listas L1 e L2
junta_listas([],L,L).
junta_listas([E|L1],L2,[E|L3]) :- junta_listas(L1,L2,L3).

% membro/2 - membro(E,L) afirma que o elemento E pertence a lista L
membro(E,[E|_]).
membro(E,[_|R]) :- membro(E,R).

% remove/3 - remove(E,L1,L2) afirma que L2 e a lista que resulta de remover o
% elemento E da lista L1
remove(_,[],[]).
remove(E,[E|R],L2) :- remove(E,R,L2), !.
remove(E,[E1|R1],[E1|R2]) :- remove(E,R1,R2).