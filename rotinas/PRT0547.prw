#Include "Totvs.ch"
#Include "FWMVCDef.ch"

Static NomePrt := "PRT0547"
Static VersaoJedi := "V1.03"

/*/{Protheus.doc} PRT0547
Fun��o para cadastro de Filial Arquivo x Protheus
@author Douglas Gregorio
@since 07/02/2019
@type function
/*/
User Function PRT0547()
    Local aArea		:=	GetArea()
    Local cNomeTab	:=	""
    Local oBrowse

    Private aRotina	:=	MenuDef()
    Private cTitulo	:=	""

    #IFDEF ENGLISH
        cNomeTab := POSICIONE("SX2",1,"UQK","X2_NOMEENG")
    #ELSE
        #IFDEF SPANISH
            cNomeTab := POSICIONE("SX2",1,"UQK","X2_NOMESPA")
        #ELSE
            cNomeTab := POSICIONE("SX2",1,"UQK","X2_NOME")
        #ENDIF
    #ENDIF

    cTitulo :=  NomePrt + " - " + Alltrim(cNomeTab) + " - " + VersaoJedi

    //Inst�nciando FWMBrowse - Somente com dicion�rio de dados
    oBrowse := FWMBrowse():New()

    //Setando a tabela de cadastro
    oBrowse:SetAlias("UQK")

    //Setando a descri��o da rotina
    oBrowse:SetDescription( cTitulo )

    //Ativa a Browse
    oBrowse:Activate()

    RestArea(aArea)
Return Nil

/*/{Protheus.doc} ModelDef
Defini��o de Modelo MVC
@author Douglas Gregorio
@since 07/02/2019
@type function
/*/
Static Function ModelDef()
    Local oModel := Nil //Cria��o do objeto do modelo de dados
    Local oStUQK := FWFormStruct(1, "UQK") //Cria��o da estrutura de dados utilizada na interface

    //Instanciando o modelo
    oModel := MPFormModel():New("MVCUQK",/* bPre */, /* bPos */,/*bCommit*/,/*bCancel*/)

    //Atribuindo formul�rios para o modelo
    oModel:AddFields("FORMUQK",/*cOwner*/,oStUQK)

    //Setando a chave prim�ria da rotina
    oModel:SetPrimaryKey({'UQK_FILARQ','UQK_FILPRO'})

    //Adicionando descri��o ao modelo
    oModel:SetDescription( cTitulo )

    //Setando a descri��o do formul�rio
    oModel:GetModel("FORMUQK"):SetDescription( cTitulo )
Return oModel

/*/{Protheus.doc} ViewDef
Defini��o do View
@author Douglas Gregorio
@since 07/02/2019
@type function
@return oView, Objeto do View
/*/
Static Function ViewDef()
    Local oModel := ModelDef()  //Cria��o do objeto do modelo de dados
    Local oStUQK := FWFormStruct(2, "UQK") //Cria��o da estrutura de dados
    Local oView := Nil //Criando oView como nulo

    //Criando a view que ser� o retorno da fun��o e setando o modelo da rotina
    oView := FWFormView():New()
    oView:SetModel(oModel)

    //Atribuindo formul�rios para interface
    oView:AddField("V_UQK", oStUQK, "FORMUQK")

    //Criando um container com nome tela com 100%
    oView:CreateHorizontalBox("TELA",100)

    //Colocando t�tulo do formul�rio
    oView:EnableTitleView('V_UQK', cTitulo )

    //For�a o fechamento da janela na confirma��o
    oView:SetCloseOnOk({||.T.})

    //O formul�rio da interface ser� colocado dentro do container
    oView:SetOwnerView("V_UQK","TELA")
Return oView

/*/{Protheus.doc} MenuDef
Defini��o de MenuDef
@author Douglas Gregorio
@since 07/02/2019
@type function
@return aRotina, Array com Fun��o dos Bot�es
/*/
Static Function MenuDef()
Return FWMVCMenu( 'PRT0547' )
