#Include "Protheus.ch"

/*/{Protheus.doc} MT120FIM

Pont de entrada nas opcoes do menu da solicitacao de compra
	 
@author  Cesar Padovani 
@since   29/11/2021
@version 1.0
@type    Ponto de entrada
/*/
User Function MTA110MNU()

aRotina[3][2] := "U_SCInclui"

Return

/*/{Protheus.doc} SCInclui

Inclusao da SC
	 
@author  Cesar Padovani 
@since   29/11/2021
@version 1.0
@type    Ponto de entrada
/*/
User Function SCInclui()

Private oFont1 := TFont():New("MS Sans Serif",,012,,.F.,,,,,.F.,.F.)
Private oFont2 := TFont():New("MS Sans Serif",,009,,.T.,,,,,.F.,.F.)
Private nRadSC  := 1

DEFINE DIALOG oDlg TITLE "Tipo" FROM 180,180 TO 350,515 PIXEL

oSTipo:= TSay():New(005,008,{||'Qual o tipo de Solicitação de Compras?'},oDlg,,oFont2,,,,.T.,,,180,20)

oGrp := TGroup():New(003,003,063,168,"",oDlg,CLR_BLACK,CLR_WHITE,.T.,.F. )

aItems := {'Compras Nacionais','Regularização de NF','Importação'}
oRadio := TRadMenu():New (17,08,aItems,,oDlg,,,,,,,,100,12,,,,.T.)
oRadio:bSetGet := {|u|Iif (PCount()==0,nRadSC,nRadSC:=u)}
oRadio:oFont:Name := "MS Sans Serif"
oRadio:oFont:nWidth := 12

oSTipo:= TSay():New(050,008,{||'Necessário escolher uma das opções acima.'},oDlg,,oFont2,,,,.T.,,,180,20)

oBtnOk  := tButton():New(068,042,'Ok'      ,oDlg,{|| (oDlg:End(),xCfgCpos(),A110Inclui("SC1",SC1->(RecNo()),3)) },35,10,,,,.T.)
oBtnCan := tButton():New(068,087,'Cancelar',oDlg,{|| oDlg:End() },35,10,,,,.T.)

ACTIVATE DIALOG oDlg CENTERED

Return

/*/{Protheus.doc} SCInclui

Inclusao da SC
	 
@author  Cesar Padovani 
@since   29/11/2021
@version 1.0
@type    Ponto de entrada
/*/
Static Function xCfgCpos()

Public cxRegNF := ""
Public cxIntPA := ""

If nRadSC==2 .or. nRadSC==3
    cxRegNF := "1"
    cxIntPA := "5"
Else 
    cxRegNF := "2"
    cxIntPA := "2"
EndIf 

Return

