#Include "Totvs.ch"
#Include "FWMVCDef.ch"

Static NomePrt := "PRT0547"
Static VersaoJedi := "V1.03"

/*/{Protheus.doc} PRT0547
Função para cadastro de Filial Arquivo x Protheus
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

    //Instânciando FWMBrowse - Somente com dicionário de dados
    oBrowse := FWMBrowse():New()

    //Setando a tabela de cadastro
    oBrowse:SetAlias("UQK")

    //Setando a descrição da rotina
    oBrowse:SetDescription( cTitulo )

    //Ativa a Browse
    oBrowse:Activate()

    RestArea(aArea)
Return Nil

/*/{Protheus.doc} ModelDef
Definição de Modelo MVC
@author Douglas Gregorio
@since 07/02/2019
@type function
/*/
Static Function ModelDef()
    Local oModel := Nil //Criação do objeto do modelo de dados
    Local oStUQK := FWFormStruct(1, "UQK") //Criação da estrutura de dados utilizada na interface

    //Instanciando o modelo
    oModel := MPFormModel():New("MVCUQK",/* bPre */, /* bPos */,/*bCommit*/,/*bCancel*/)

    //Atribuindo formulários para o modelo
    oModel:AddFields("FORMUQK",/*cOwner*/,oStUQK)

    //Setando a chave primária da rotina
    oModel:SetPrimaryKey({'UQK_FILARQ','UQK_FILPRO'})

    //Adicionando descrição ao modelo
    oModel:SetDescription( cTitulo )

    //Setando a descrição do formulário
    oModel:GetModel("FORMUQK"):SetDescription( cTitulo )
Return oModel

/*/{Protheus.doc} ViewDef
Definição do View
@author Douglas Gregorio
@since 07/02/2019
@type function
@return oView, Objeto do View
/*/
Static Function ViewDef()
    Local oModel := ModelDef()  //Criação do objeto do modelo de dados
    Local oStUQK := FWFormStruct(2, "UQK") //Criação da estrutura de dados
    Local oView := Nil //Criando oView como nulo

    //Criando a view que será o retorno da função e setando o modelo da rotina
    oView := FWFormView():New()
    oView:SetModel(oModel)

    //Atribuindo formulários para interface
    oView:AddField("V_UQK", oStUQK, "FORMUQK")

    //Criando um container com nome tela com 100%
    oView:CreateHorizontalBox("TELA",100)

    //Colocando título do formulário
    oView:EnableTitleView('V_UQK', cTitulo )

    //Força o fechamento da janela na confirmação
    oView:SetCloseOnOk({||.T.})

    //O formulário da interface será colocado dentro do container
    oView:SetOwnerView("V_UQK","TELA")
Return oView

/*/{Protheus.doc} MenuDef
Definição de MenuDef
@author Douglas Gregorio
@since 07/02/2019
@type function
@return aRotina, Array com Função dos Botões
/*/
Static Function MenuDef()
Return FWMVCMenu( 'PRT0547' )
