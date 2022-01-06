#Include "Protheus.ch"
#Include "Fileio.ch."
#Include "Topconn.ch"
#Include "TbiConn.ch"   
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} MATA095

Ponto de entrada no Cadastro de Aprovadores
	 
@author  Cesar Padovani 
@since   11/09/2021
@version 1.0
@type    Ponto de entrada
/*/
User Function MATA095()

Local aParam     := PARAMIXB
Local xRet       := .T.
Local oObj       := Nil
Local cIdPonto   := ''
Local cIdModel   := ''
Local nOper      := 0

//Se tiver parâmetros
If aParam <> NIL
    ConOut("> "+aParam[2])
        
    //Pega informações dos parâmetros
    oObj     := aParam[1]
    cIdPonto := aParam[2]
    cIdModel := aParam[3]
        
    //Adição de opções no Ações Relacionadas dentro da tela
    If cIdPonto == 'BUTTONBAR'
        xRet := {}
        aAdd(xRet, {"Grupos de Produtos", "", {|| MsgRun("Verificando Grupos...",,{|| AtuGrupos() }) }, "Tooltip 1"})
        
    //Pós configurações do Formulário
    ElseIf cIdPonto == 'FORMPOS'
        xRet := .T.
        
    //Validação ao clicar no Botão Confirmar
    ElseIf cIdPonto == 'MODELPOS'
        //Se o campo de contato estiver em branco, não permite prosseguir
        //If FwAlertYesNo("COnfirma ?","Confirmacao")
        //    xRet := .T.
        //Else
        //    xRet := .F.
        //EndIf
        
    //Pré validações do Commit
    ElseIf cIdPonto == 'FORMCOMMITTTSPRE'
        
    //Pós validações do Commit
    ElseIf cIdPonto == 'FORMCOMMITTTSPOS'
            
    //Commit das operações (antes da gravação)
    ElseIf cIdPonto == 'MODELCOMMITTTS'
            
    //Commit das operações (após a gravação)
    ElseIf cIdPonto == 'MODELCOMMITNTTS'
        nOper := oObj:nOperation
            
        //Se for inclusão, mostra mensagem de sucesso
        //If nOper == 3
        //    Aviso('Atenção', 'Grupo criado com sucesso!', {'OK'}, 03)
        //EndIf
    EndIf
EndIf
    
Return xRet

/*/{Protheus.doc} AtuGrupos

Atualiza grupo de produtos do Aprovador
	 
@author  Cesar Padovani 
@since   11/09/2021
@version 1.0
@type    Ponto de entrada
/*/
Static Function AtuGrupos()

Local aArea    := GetArea()
Local oTable   := Nil
Local aColumns := {}    
//Local bInit   	:= {|| xMarkinit() }

Private oMark
Private cTable := ""   
Private nOpca  := 0
Private aSeek  := {}
     
// Cria tabela temporaria
cTable := fGeraTab(@oTable) 
    
DbSelectArea(cTable)
DbSetOrder(1)
DbGoTop()

DEFINE MSDIALOG oDlgGrupo TITLE "Grupos de Produtos do Aprovador "+Alltrim(SAK->AK_NOME) FROM 010,050 TO 550,950 PIXEL
    
// Adiciona Pesquisa
aAdd(aSeek,{"Grupo",{{"","C",04,0,"Grupo","@!"}} } )

//Constrói estrutura das colunas do FWMarkBrowse
aColumns := fBuildColumns()

aRotina := {}
ADD OPTION aRotina TITLE "Fechar"    Action "oDlgGrupo:End()"     OPERATION 4 ACCESS 0	
ADD OPTION aRotina TITLE "Atualizar" Action "U_GrvZA1(cTable)" OPERATION 4 ACCESS 0	

//Criando o FWMarkBrowse
oMark := FWMarkBrowse():New()
oMark:SetAlias(cTable)
oMark:SetOwner(oDlgGrupo)
oMark:SetDescription("Grupos de Produtos do Aprovador "+SAK->AK_NOME)
oMark:DisableReport()
oMark:SetFieldMark('MK_OK')    //Campo que será marcado/descmarcado
oMark:SetMark("W1",cTable,"MK_OK")
oMark:SetTemporary(.T.)
oMark:SetColumns(aColumns)
oMark:oBrowse:SetSeek(.T.,aSeek)
oMark:DisableDetails(.F.)

// Atualiza os grupos
AtGrupos(oMark)

// Marca os grupos que o aprovador possui acesso
cMarca    := oMark:cMark
cAliasBrw := oMark:Alias()

(cAliasBrw)->(dbGoTop())
While (cAliasBrw)->(!Eof())
    DbSelectArea("ZA1")
    DbSetOrder(1)
    If DbSeek(xFilial("ZA1")+SAK->AK_COD+(cAliasBrw)->GRUPO)
        RecLock(cAliasBrw,.F.)
        (cAliasBrw)->MK_OK := cMarca
        (cAliasBrw)->(MsUnlock())
    EndIf
    
    (cAliasBrw)->(DbSkip())
EndDo

oMark:oBrowse:Refresh(.T.)

//Ativando a janela
oMark:Activate()

ACTIVATE MSDIALOG oDlgGrupo CENTERED 

oTable:Delete()
oMark:DeActivate()
FreeObj(oTable)
FreeObj(oMark)
RestArea( aArea )

Return 
 
/*
    Descrição: Gera tabela temporária.
    Data     : 11/09/2021
    Param    : Object, Endereço do content da temporária
    Return   : Character, nome da tabela criada.    
*/
Static Function fGeraTab(oTable)
 
Local cAliasTmp := "TRBGRUPO"
Local aFields   := {}
        
If Select("TRBGRUPO")<>0
    TRBGRUPO->(DbCloseArea())
EndIf 
//Monta estrutura de campos da temporária
aAdd(aFields, { "MK_OK"    , "C", 2, 0 })
aAdd(aFields, { "GRUPO" , GetSx3Cache("BM_GRUPO","X3_TIPO"), GetSx3Cache("BM_GRUPO","X3_TAMANHO"), GetSx3Cache("BM_GRUPO","X3_DECIMAL")  })
aAdd(aFields, { "DESCRI", GetSx3Cache("BM_DESC" ,"X3_TIPO"), GetSx3Cache("BM_DESC" ,"X3_TAMANHO"), GetSx3Cache("BM_DESC" ,"X3_DECIMAL")  })
        
oTable:= FWTemporaryTable():New(cAliasTmp)
oTable:SetFields( aFields )
oTable:AddIndex("01", {"GRUPO"} )    
oTable:Create()    
 
Return oTable:GetAlias()
 
/*
    Descrição: Constrói estrutura das colunas que serão apresentadas na tela.
    Data     : 11/06/2020
    Return   : Nil        
*/
Static Function fBuildColumns()
     
Local nX       := 0 
Local aColumns := {}
Local aStruct  := {}
    
AAdd(aStruct, {"MK_OK"    , "C", 2 , 0,""})
AAdd(aStruct, {"GRUPO" , GetSx3Cache("BM_GRUPO","X3_TIPO"), GetSx3Cache("BM_GRUPO","X3_TAMANHO"), GetSx3Cache("BM_GRUPO","X3_DECIMAL"), GetSx3Cache("BM_GRUPO","X3_TITULO")  })
AAdd(aStruct, {"DESCRI", GetSx3Cache("BM_DESC" ,"X3_TIPO"), GetSx3Cache("BM_DESC" ,"X3_TAMANHO"), GetSx3Cache("BM_DESC" ,"X3_DECIMAL"), GetSx3Cache("BM_DESC" ,"X3_TITULO")  })
            
For nX := 2 To Len(aStruct)    
    AAdd(aColumns,FWBrwColumn():New())
    aColumns[Len(aColumns)]:SetData( &("{||"+aStruct[nX][1]+"}") )
    aColumns[Len(aColumns)]:SetTitle(aStruct[nX][5])
    aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
    aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])              
Next nX

Return aColumns

Static Function AtGrupos(oMark)

// Popula a tabela temporaria com o cadastro de grupos
DbSelectArea("SBM")
DbSetOrder(1)
DbGoTop()
Do While !Eof()
    DbSelectArea("TRBGRUPO")
    RecLock("TRBGRUPO",.T.)
    TRBGRUPO->GRUPO  := SBM->BM_GRUPO
    TRBGRUPO->DESCRI := SBM->BM_DESC
    MsUnLock()

    DbSelectArea("SBM")
    DbSkip()
EndDo

Return

Static Function AllMarkBrw(oMark)

Local cAliasBrw := oMark:Alias()

AtGrupos(oMark)

(cAliasBrw)->(dbGoTop())
While (cAliasBrw)->(!Eof())
    DbSelectArea("ZA1")
    DbSetOrder(1)
    If DbSeek(xFilial("ZA1")+SAK->AK_COD+(cAliasBrw)->GRUPO)
        oMark:MarkRec()
    EndIf
    
    (cAliasBrw)->(DbSkip())
EndDo

oMark:Refresh(.T.)
oMark:GoTop(.T.)
    
Return

Static Function xMarkinit()

oMark:oBrowse:GoTop()
oMark:MarkRec()

oMark:oBrowse:Refresh(.T.)

Return

User Function GrvZA1(cTable)

DbSelectArea(cTable)
DbGoTop()
Do While !Eof()
    If !Empty((cTable)->MK_OK)
        DbSelectArea("ZA1")
        DbSetOrder(1)
        If !DbSeek(xFilial("ZA1")+SAK->AK_COD+(cTable)->GRUPO)
            RecLock("ZA1",.T.)
            ZA1->ZA1_FILIAL := xFilial("ZA1")
            ZA1->ZA1_APROV  := SAK->AK_COD
            ZA1->ZA1_GRUPO  := (cTable)->GRUPO
            MsUnLock()
        EndIf
    Else
        DbSelectArea("ZA1")
        DbSetOrder(1)
        If DbSeek(xFilial("ZA1")+SAK->AK_COD+(cTable)->GRUPO)
            RecLock("ZA1",.F.)
            Delete
            MsUnLock()
        EndIf
    EndIf 

    DbSelectArea(cTable)
    DbSkip()
EndDo

oDlgGrupo:End()

Return
