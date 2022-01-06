#Include "Protheus.ch"
#Include "Fileio.ch."
#Include "Topconn.ch"
#Include "TbiConn.ch"   
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} MATA114

Ponto de entrada no Cadastro de Grupos de Aprovacao
	 
@author  Cesar Padovani 
@since   03/10/2021
@version 1.0
@type    Ponto de entrada
/*/
User Function MATA114()

Local aParam     := PARAMIXB
Local xRet       := .T.
Local oObj       := Nil
Local cIdPonto   := ''
Local cIdModel   := ''

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
        aAdd(xRet, {"Grupos do Aprovador", "", {|| MsgRun("Verificando Grupos...",,{|| AtuGrupos() }) }, "Tooltip 1"})
        
    //Pós configurações do Formulário
    ElseIf cIdPonto == 'FORMPOS'

    //Validação ao clicar no Botão Confirmar
    ElseIf cIdPonto == 'MODELPOS'
        
    //Pré validações do Commit
    ElseIf cIdPonto == 'FORMCOMMITTTSPRE'
        
    //Pós validações do Commit
    ElseIf cIdPonto == 'FORMCOMMITTTSPOS'
            
    //Commit das operações (antes da gravação)
    ElseIf cIdPonto == 'MODELCOMMITTTS'
            
    //Commit das operações (após a gravação)
    ElseIf cIdPonto == 'MODELCOMMITNTTS'

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

Private oGrupos
Private cTable := ""   
Private nOpca  := 0
Private aSeek  := {}
Private cxApr  := ""
     
// Verifica o Aprovador que esta posicionado na Grid
oModelx := FwModelActive()
oModelxDet := oModelx:GetModel("DetailSAL")
oModelxDet:GetLine()
cxApr := oModelxDet:GetValue("AL_APROV")

DbSelectArea("SAK")
DbSetOrder(1)
If DbSeek(xFilial("SAK")+cxApr)

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
    ADD OPTION aRotina TITLE "Fechar"    Action "oDlgGrupo:End()"     OPERATION 3 ACCESS 0	

    //Criando o FWMarkBrowse
    oGrupos := FWMBrowse():New()
    oGrupos:SetAlias(cTable)
    oGrupos:SetOwner(oDlgGrupo)
    oGrupos:SetDescription("Grupos de Produtos do Aprovador "+SAK->AK_NOME)
    oGrupos:DisableReport()
    oGrupos:SetTemporary(.T.)
    oGrupos:SetColumns(aColumns)
    oGrupos:SetSeek(.T.,aSeek)
    oGrupos:DisableDetails(.F.)

    // Adiciona os grupos do Aprovador
    cAliasBrw := oGrupos:Alias()

    DbSelectArea("ZA1")
    DbSetOrder(1)
    DbGoTop()
    DbSeek(xFilial("ZA1")+SAK->AK_COD,.T.)
    Do While !Eof() .and. Alltrim(ZA1->ZA1_APROV)==Alltrim(SAK->AK_COD)
        DbSelectArea("SBM")
        DbSetOrder(1)
        If DbSeek(xFilial("SBM")+ZA1->ZA1_GRUPO)
            RecLock(cAliasBrw,.T.)
            (cAliasBrw)->GRUPO  := SBM->BM_GRUPO
            (cAliasBrw)->DESCRI := SBM->BM_DESC
            (cAliasBrw)->(MsUnlock())
        EndIf 

        DbSelectArea("ZA1")
        DbSkip()
    EndDo
    (cAliasBrw)->(DbGoTop())

    oGrupos:Refresh(.T.)

    //Ativando a janela
    oGrupos:Activate()

    ACTIVATE MSDIALOG oDlgGrupo CENTERED 

    oTable:Delete()
    oGrupos:DeActivate()
    FreeObj(oTable)
    FreeObj(oGrupos)
    RestArea( aArea )
Else 
    FwAlertWarning("Aprovador nao identificado")
Endif

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
    
AAdd(aStruct, {"GRUPO" , GetSx3Cache("BM_GRUPO","X3_TIPO"), GetSx3Cache("BM_GRUPO","X3_TAMANHO"), GetSx3Cache("BM_GRUPO","X3_DECIMAL"), GetSx3Cache("BM_GRUPO","X3_TITULO")  })
AAdd(aStruct, {"DESCRI", GetSx3Cache("BM_DESC" ,"X3_TIPO"), GetSx3Cache("BM_DESC" ,"X3_TAMANHO"), GetSx3Cache("BM_DESC" ,"X3_DECIMAL"), GetSx3Cache("BM_DESC" ,"X3_TITULO")  })
            
For nX := 1 To Len(aStruct)    
    AAdd(aColumns,FWBrwColumn():New())
    aColumns[Len(aColumns)]:SetData( &("{||"+aStruct[nX][1]+"}") )
    aColumns[Len(aColumns)]:SetTitle(aStruct[nX][5])
    aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
    aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])              
Next nX

Return aColumns
