#include 'protheus.ch'
#include 'parmtype.ch'
#Include "Topconn.ch"
#Include "FWMVCDEF.CH"

/*{Protheus.doc} MTA094RO
O Ponto de Entrada MTA094RO, localizado na rotina de Liberação de Documento, permite adicionar 
opções no item Outras Ações.

@author Tiago Dantas da Cruz  
@since 25/07/2019
@Project MIT044 - P04024 - G198 e GAP 180 – Cadastro proposta de capital e Aprovação
*/
User Function MTA094RO()

Local aRotina:= PARAMIXB
	
    //Tiago Dantas da Cruz - 05/11/2019
    If FindFunction("U_F040240I")	
    	aRotina:= U_F040240I(PARAMIXB)
	EndIf

   // Cesar Padovani | 19/09/2021
    // Adicionar nova opção para aprovação de todos os itens do mesmo Aprovador/Nivel
    Aadd(aRotina,{"Aprovar por Documento"  ,"U_AprXDoc()", 0, 4,0,NIL})
    Aadd(aRotina,{"Historico de Alteracoes","U_HisXAlt()", 0, 4,0,NIL})
    Aadd(aRotina,{"Visualizar X1","U_VisX1()", 0, 4,0,NIL})
    Aadd(aRotina,{"Remover X1","U_RemX1()", 0, 4,0,NIL})

Return (aRotina)

/*/{Protheus.doc} AprXDoc

Aprovacao por Documento
	 
@author  Cesar Padovani 
@since   19/09/2021
@version 1.0
@type    Rotina
/*/
User Function AprXDoc()

Local oFont1   := TFont():New("MS Sans Serif",,010,,.F.,,,,,.F.,.F.)
Local cNumPedx := Alltrim(SCR->CR_NUM)
Local cComprad := UsrRetName(GetAdvfVal("SC7","C7_USER",xFilial("SC7")+cNumPedx,1))
Local cFornecx := RetForn()
Local nY

Private aHeader   := {}
Private aCols     := {}
Private cCadastro := "Aprovar Todos"
Private nOpca     := 0

DEFINE MSDIALOG DlgAprDoc TITLE "Aprovacao do Documento "+Alltrim(SCR->CR_NUM) FROM 010,050 TO 375,650 PIXEL

oSNumPedx := TSay():New(035,005,{||'Pedido:'},DlgAprDoc,,oFont1,,,,.T.,,,35,20)
oGNumPedx := TGet():New(035,035,{|u| If(PCount()>0,cNumPedx:=u,cNumPedx)}, DlgAprDoc, 30,7,PesqPict("SCR","CR_NUM"),{|o| .T. },,,,,,.T.,,,{|| .F. },,,,.F.,,,'cNumPedx')

oSComprad := TSay():New(035,080,{||'Comprador:'},DlgAprDoc,,oFont1,,,,.T.,,,35,20)
oGComprad := TGet():New(035,120,{|u| If(PCount()>0,cComprad:=u,cComprad)}, DlgAprDoc, 130,7,"@!",{|o| .T. },,,,,,.T.,,,{|| .F. },,,,.F.,,,'cComprad')

oSFornecx := TSay():New(169,005,{||'Fornecedor:'},DlgAprDoc,,oFont1,,,,.T.,,,35,20)
oGFornecx := TGet():New(169,045,{|u| If(PCount()>0,cFornecx:=u,cFornecx)}, DlgAprDoc, 200,7,PesqPict("SA2","A1_NOME"),{|o| .T. },,,,,,.T.,,,{|| .F. },,,,.F.,,,'cFornecx')

DbSelectArea("SX3")
DbSetOrder(2)
DbSeek("CR_TIPO")
//              Título        Campo         Máscara         Tamanho         Decimal         Valid         Usado  Tipo         F3         Combo
aAdd(aHeader, {SX3->X3_TITULO,SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,".T.", SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CBOX} )

DbSeek("CR_NIVEL")
//              Título        Campo         Máscara         Tamanho         Decimal         Valid         Usado  Tipo         F3         Combo
aAdd(aHeader, {SX3->X3_TITULO,SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,".T.", SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CBOX} )

//             Título                  Campo       Máscara  Tamanho  Decimal  Valid  Usado   Tipo  F3  Combo
aAdd(aHeader, {"Aprovador Responsavel","CR_XAPROV","@"     ,25      ,0       ,".T."  ,".T.", "C"  ,"" ,""    } )

//             Título            Campo       Máscara  Tamanho  Decimal  Valid  Usado   Tipo  F3  Combo
aAdd(aHeader, {"Situacao Atual","CR_XSITUA" ,"@"     ,15      ,0       ,".T."  ,".T.", "C"  ,"" ,""    } )

//             Título                  Campo       Máscara  Tamanho  Decimal  Valid  Usado   Tipo  F3  Combo
aAdd(aHeader, {"Avaliado Por","CR_XAVALI","@"     ,25      ,0       ,".T."  ,".T.", "C"  ,"" ,""    } )

DbSeek("CR_DATALIB")
//              Título        Campo         Máscara         Tamanho         Decimal         Valid         Usado  Tipo         F3         Combo
aAdd(aHeader, {SX3->X3_TITULO,SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,".T.", SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CBOX} )

DbSeek("CR_GRUPO")
//              Título        Campo         Máscara         Tamanho         Decimal         Valid         Usado  Tipo         F3         Combo
aAdd(aHeader, {SX3->X3_TITULO,SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,".T.", SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CBOX} )

DbSeek("CR_OBS")
//              Título        Campo         Máscara         Tamanho         Decimal         Valid         Usado  Tipo         F3         Combo
aAdd(aHeader, {SX3->X3_TITULO,SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,".T.", SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CBOX} )

DbSeek("CR_ITGRP")
//              Título        Campo         Máscara         Tamanho         Decimal         Valid         Usado  Tipo         F3         Combo
aAdd(aHeader, {SX3->X3_TITULO,SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,".T.", SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CBOX} )

//             Registro    Campo       Máscara Tamanho  Decimal  Valid  Usado   Tipo  F3  Combo
aAdd(aHeader, {"Registro","CR_XRECNO","@"     ,15      ,0       ,".T."  ,".T.", "C"  ,"" ,""    } )

// Atualizando os itens
Processa({|| fAtuDados() })

//Grid
Private oMsAprDoc := MsNewGetDados():New(050,;  //nTop      - Linha Inicial
                                    005,;       //nLeft     - Coluna Inicial
                                    165,;       //nBottom   - Linha Final
                                    300,;       //nRight    - Coluna Final
                                    NIL,;       //nStyle    - Estilos para edição da Grid (GD_INSERT = Inclusão de Linha; GD_UPDATE = Alteração de Linhas; GD_DELETE = Exclusão de Linhas)
                                    "U_LinOk",; //cLinhaOk  - Validação da linha
                                    ,;          //cTudoOk   - Validação de todas as linhas
                                    "",;        //cIniCpos  - Função para inicialização de campos
                                    ,;          //aAlter    - Colunas que podem ser alteradas
                                    ,;          //nFreeze   - Número da coluna que será congelada
                                    9999,;      //nMax      - Máximo de Linhas
                                    ,;          //cFieldOK  - Validação da coluna
                                    ,;          //cSuperDel - Validação ao apertar '+'
                                    ,;          //cDelOk    - Validação na exclusão da linha
                                    DlgAprDoc,; //oWnd      - Janela que é a dona da grid
                                    aHeader,;   //aHeader   - Cabeçalho da Grid
                                    aCols)      //aCols     - Dados da Grid


ACTIVATE MSDIALOG DlgAprDoc CENTERED ON INIT EnchoiceBar(DlgAprDoc,{|| (nOpca:=1,DlgAprDoc:End()) },{|| DlgAprDoc:End() },/*lMsgDel*/,/*aButton*/,/*nRecno*/,/*cAlias*/,/*lMarshups*/,/*lImpCad*/,/*lPadrao*/,.T.,/*lWalkThru*/,/*cProfileID*/)

If nOpca==1
    If FwAlertYesNo("Confirma a aprovacao de todos os itens?","Confirmacao")
        // Posiciona no Cadastro do Aprovador
        DbSelectArea("SAK")
        DbSetOrder(2)
        DbGoTop()
        If DbSeek(xFilial("SAK")+RetCodUsr())
            Begin Transaction

            nPosRec := GDFieldPos("CR_XRECNO")
            For nY:=1 To Len(aCols)
                // Posiciona no registro de pendencia de aprovacao
                DbSelectArea("SCR")
                DbGoTo(aCols[nY][nPosRec])

                // Inicia o execauto mvc da aprovacao de documenros
                //-- Códigos de operações possíveis:
                //--    "001" // Liberado
                //--    "002" // Estornar
                //--    "003" // Superior
                //--    "004" // Transferir Superior
                //--    "005" // Rejeitado
                //--    "006" // Bloqueio
                //--    "007" // Visualizacao

                //-- Seleciona a operação de aprovação de documentos
                cSetOp := "001" // Liberado
                A094SetOp(cSetOp)

                //-- Carrega o modelo de dados e seleciona a operação de aprovação (UPDATE)
                oModel094 := FWLoadModel('MATA094')
                oModel094:SetOperation( MODEL_OPERATION_UPDATE )
                oModel094:Activate()

                //-- Valida o formulário
                lOk := oModel094:VldData()

                If lOk
                    //-- Se validou, grava o formulário
                    lOk := oModel094:CommitData()
                EndIf

                //-- Avalia erros
                If !lOk
                    //-- Busca o Erro do Modelo de Dados
                    aErro := oModel094:GetErrorMessage()
                        
                    //-- Monta o Texto que será mostrado na tela
                    //AutoGrLog("Id do formulário de origem:" + ' [' + AllToChar(aErro[01]) + ']')
                    //AutoGrLog("Id do campo de origem: "     + ' [' + AllToChar(aErro[02]) + ']')
                    //AutoGrLog("Id do formulário de erro: "  + ' [' + AllToChar(aErro[03]) + ']')
                    //AutoGrLog("Id do campo de erro: "       + ' [' + AllToChar(aErro[04]) + ']')
                    //AutoGrLog("Id do erro: "                + ' [' + AllToChar(aErro[05]) + ']')
                    //AutoGrLog("Mensagem do erro: "          + ' [' + AllToChar(aErro[06]) + ']')
                    //AutoGrLog("Mensagem da solução:"        + ' [' + AllToChar(aErro[07]) + ']')
                    //AutoGrLog("Valor atribuído: "           + ' [' + AllToChar(aErro[08]) + ']')
                    //AutoGrLog("Valor anterior: "            + ' [' + AllToChar(aErro[09]) + ']')

                    //-- Mostra a mensagem de Erro
                    cString  := AllToChar(aErro[06])
                    FwAlertWarning("Erro na aprovacao do documento : "+cString)
                EndIf

                //-- Desativa o modelo de dados
                oModel094:DeActivate()

            Next

            End Transaction
        Else
            FwAlertWarning("Usuario nao cadastrado como Aprovador.","Cadastro de Aprovadores")
        EndIf 
    EndIf 
EndIf

Return

/*/{Protheus.doc} fAtuDados

Atualiza os dados da tela
	 
@author  Cesar Padovani 
@since   19/09/2021
@version 1.0
@type    Rotina
/*/
Static Function fAtuDados()

cQuery := ""
cQuery += "SELECT CR_TIPO,CR_NIVEL,CR_USER,CR_DATALIB,CR_APROV,CR_ITGRP,R_E_C_N_O_ "
cQuery += "FROM "+RetSqlName("SCR")+" "
cQuery += "WHERE D_E_L_E_T_='' "
cQuery += "AND CR_FILIAL='"+xFilial("SCR")+"' "
cQuery += "AND CR_NUM='"+Alltrim(SCR->CR_NUM)+"' "
cQuery += "AND CR_USER='"+Alltrim(RetCodUsr())+"' "
cQuery += "AND CR_STATUS='02' "
cQuery := ChangeQuery(cQuery)

If Select("TRBSCR")<>0
    TRBSCR->(DbCloseArea())
EndIf 
TCQUERY cQuery NEW ALIAS "TRBSCR"
aTam := TamSx3("CR_DATALIB")
TcSetField("TRBSCR","CR_DATALIB",aTam[3],aTam[1],aTam[2])

DbSelectArea("TRBSCR")
DbGoTop()

If TRBSCR->(!Eof())
    Do While !Eof()
        DbSelectArea("SCR")
        DbGoTo(TRBSCR->R_E_C_N_O_)

        aAdd(aCols,{SCR->CR_TIPO,SCR->CR_NIVEL,UsrRetName(SCR->CR_USER),"Pendente",SCR->CR_APROV,SCR->CR_DATALIB,SCR->CR_GRUPO,SCR->CR_OBS,SCR->CR_ITGRP,TRBSCR->R_E_C_N_O_,.F.})

        DbSelectArea("TRBSCR")
        DbSkip()
    EndDo
Else
    FwAlertWarning("Nenhum registro encontrado.")
EndIf 

Return

/*/{Protheus.doc} RetForn

Retorna a razao social do fornecedor
	 
@author  Cesar Padovani 
@since   19/09/2021
@version 1.0
@type    Rotina
/*/
Static Function RetForn()

Local cRet := ""

DbSelectArea("SC7")
DbSetOrder(1)
DbGoTOp()
DbSeek(xFilial("SC7")+Alltrim(SCR->CR_NUM))

cRet := GetAdvfVal("SA2","A2_NOME",xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA,1)

Return cRet

/*/{Protheus.doc} LinOk

Validação da linha do aCols
	 
@author  Cesar Padovani 
@since   19/09/2021
@version 1.0
@type    Rotina
/*/

User Function LinOk()

Return .T.

/*/{Protheus.doc} HisXAlt

Apresenta os historicos de alteracoes do pedido de compra
	 
@author  Cesar Padovani 
@since   17/10/2021
@version 1.0
@type    Rotina
/*/
User Function HisXAlt()

Private aHeader   := {}
Private aCols     := {}
Private cCadastro := "Historico de Alteracoes do Documento "+Alltrim(SCR->CR_NUM)

DEFINE MSDIALOG DlgHisAlt TITLE "Historico de Alteracoes" FROM 010,050 TO 500,1380 PIXEL

DbSelectArea("SX3")
DbSetOrder(1)
DbGoTop()
DbSeek("ZA3",.T.)
Do While !Eof() .and. Alltrim(SX3->X3_ARQUIVO)=="ZA3"
    If Alltrim(X3_CAMPO)$"ZA3_FILIAL,ZA3_NUM"
        DbSelectArea("SX3")
        DbSkip()
        Loop
    EndIf 

    cxTitulo := IIF(Alltrim(SX3->X3_CAMPO)=="ZA3_OBS","Justif.",SX3->X3_TITULO)
    //              Título        Campo         Máscara         Tamanho         Decimal         Valid         Usado  Tipo         F3         Combo
    aAdd(aHeader, {cxTitulo,SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,".T.", SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CBOX} )

    DbSelectArea("SX3")
    DbSkip()
EndDo

// Atualiza os itens
DbSelectArea("ZA3")
DbSetOrder(2)
DbGoTop()
DbSeek(xFilial("ZA3")+Alltrim(SCR->CR_NUM),.T.)
Do While !Eof() .and. Alltrim(ZA3->ZA3_NUM)==Alltrim(SCR->CR_NUM)
    aAdd(aCols,{ZA3->ZA3_DTALT,ZA3->ZA3_HRALT,ZA3->ZA3_ITEM,ZA3_PRODDE,ZA3_PRODAT,ZA3_QTDEDE,ZA3_QTDEAT,ZA3_PRECDE,ZA3_PRECAT,ZA3->ZA3_ENTRDE,ZA3->ZA3_ENTRAT,ZA3->ZA3_TPFRDE,ZA3->ZA3_TPFRAT,ZA3->ZA3_CONDDE,ZA3->ZA3_ADTODE,ZA3->ZA3_CONDAT,ZA3->ZA3_ADTOAT,ZA3->ZA3_PRFADT,ZA3->ZA3_NUMADT,ZA3->ZA3_VALADT,ZA3->ZA3_OBS,.F.})

    DbSelectArea("ZA3")
    DbSkip()
EndDo


//Grid
Private oMsHisAlt := MsNewGetDados():New(035,;  //nTop      - Linha Inicial
                                    005,;       //nLeft     - Coluna Inicial
                                    240,;       //nBottom   - Linha Final
                                    665,;       //nRight    - Coluna Final
                                    NIL,;       //nStyle    - Estilos para edição da Grid (GD_INSERT = Inclusão de Linha; GD_UPDATE = Alteração de Linhas; GD_DELETE = Exclusão de Linhas)
                                    "U_LinOk",; //cLinhaOk  - Validação da linha
                                    ,;          //cTudoOk   - Validação de todas as linhas
                                    "",;        //cIniCpos  - Função para inicialização de campos
                                    ,;          //aAlter    - Colunas que podem ser alteradas
                                    ,;          //nFreeze   - Número da coluna que será congelada
                                    9999,;      //nMax      - Máximo de Linhas
                                    ,;          //cFieldOK  - Validação da coluna
                                    ,;          //cSuperDel - Validação ao apertar '+'
                                    ,;          //cDelOk    - Validação na exclusão da linha
                                    DlgHisAlt,; //oWnd      - Janela que é a dona da grid
                                    aHeader,;   //aHeader   - Cabeçalho da Grid
                                    aCols)      //aCols     - Dados da Grid


ACTIVATE MSDIALOG DlgHisAlt CENTERED ON INIT EnchoiceBar(DlgHisAlt,{|| ( DlgHisAlt:End() ) },{|| DlgHisAlt:End() },/*lMsgDel*/,/*aButton*/,/*nRecno*/,/*cAlias*/,/*lMarshups*/,/*lImpCad*/,/*lPadrao*/,.F.,/*lWalkThru*/,/*cProfileID*/)

Return 
