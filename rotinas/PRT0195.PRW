#INCLUDE "Protheus.ch"
#INCLUDE "ParmType.ch"
//#INCLUDE "VlCfgEml.ch"

Static nTopCont			:= 003
Static nEsqCont			:= 001
Static nAltCont			:= 009
Static nDistPad			:= 002
Static nAltBot			:= 013
Static nDistAPad		:= 004
Static nDistEtq			:= 001
Static nAltEtq			:= 007
Static nLargEtq			:= 035
Static nLargBot			:= 040
Static cHK				:= "&"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณRtFunName  บAutor  ณPablo Gollan Carreras บ Data ณ26/11/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณRotina para retornar um nome de rotina de chamada formatado       บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[L] : Utilizar a rotina de chamada de menu ou atual?         บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExp01[L] : Nome da rotina de chamada formatado                    บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGENERICO                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function RtFunName(lChamada,lDelimita)

	Local cRet				:= ""
	Local ni				:= 0
	Local aLstCarRm			:= {"U_",".T.",".F."}
	Local nTamPar			:= 0
	Local nPosRot			:= 0

	PARAMTYPE 0	VAR lChamada	AS Logical	OPTIONAL	DEFAULT .T.
	PARAMTYPE 1	VAR lDelimita	AS Logical	OPTIONAL	DEFAULT .F.

	If Type("PARAMIXB") == "A" .AND. IsInCallStack("EXECBLOCK")
		nTamPar := Len(PARAMIXB)
		If nTamPar >= 1 .AND. ValType(PARAMIXB[1]) == "L"
			lChamada := PARAMIXB[1]
		Endif
		If nTamPar >= 2 .AND. ValType(PARAMIXB[2]) == "L"
			lDelimita := PARAMIXB[2]
		Endif
		nPosRot := 2
	Endif
	cRet := Upper(AllTrim(AllToChar(IIf(lChamada,FunName(),ProcName(nPosRot)))))
	If !Empty(cRet)
		For ni := 1 to Len(aLstCarRm)
			cRet := StrTran(cRet,aLstCarRm[ni],"")
		Next ni
		If lDelimita
			cRet := "[" + cRet + "]" + Space(1)
		Endif
	Endif

Return cRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณFrmtHelp   บAutor  ณPablo Gollan Carreras บ Data ณ03/02/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณRotina para formatar uma string em uma array respeitando          บฑฑ
ฑฑบ          ณum tamanho maximo para visualizacao de help de campo              บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[C] : Texto do help                                          บฑฑ
ฑฑบ          ณExp02[N} : Tamanho maximo do texto por linha                      บฑฑ
ฑฑบ          ณExp03[L} : Determina se o retorno deve ser uma array ou string    บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGenerico                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function FrmtHelp(cTexto,nLimite,lArray)

	Local uRet			:= Nil
	Local aRet			:= {}
	Local ni			:= 0
	Local nTam			:= 0
	Local nCont			:= 1
	Local nPos			:= 0
	Local cVogais		:= "AEIOUมษอำฺยสฮิÛภศฬาูรีฤหฯึÜ"
	Local cConsoa		:= "BCDFGHJKLMNPQRSTVXWYZวั"
	Local cPontua		:= "(){}[]:.,;"
	Local cNum			:= "0123456789"
	Local cEspaco		:= " " + CRLF
	Local lPontua 		:= .F.
	Local lUltVog		:= .F.
	Local lEncVoc		:= .F.
	Local lEncCon		:= .F.
	Local lTritongo 	:= .F.
	Local lEspaco		:= .F.
	Local lConEsp		:= .F.
	Local lPalDuas		:= .F.
	Local lPalTres		:= .F.

	PARAMTYPE 0	VAR cTexto		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 1	VAR	nLimite		AS Numeric		OPTIONAL	DEFAULT nTAMSX1H
	PARAMTYPE 2	VAR lArray		AS Logical		OPTIONAL	DEFAULT .T.

	If Empty(cTexto)
		Return aRet
	Endif
	cTexto	:= AllTrim(cTexto)
	nTam 	:= Len(cTexto)
	aRet	:= Array(1)
	nPos	:= Len(aRet)
	If nTam > nLimite
		aRet[nPos] := ""
		For ni := 1 to nTam
			If ni > 1
				lPontua := Upper(Substr(cTexto,ni,1)) $ (cPontua + cNum)
				lUltVog	:= Upper(Right(aRet[nPos],1)) $ cVogais
				lEncVoc	:= Upper(Substr(cTexto,ni,1)) $ cVogais .AND. lUltVog
				lEncCon	:= Upper(Substr(cTexto,ni,1)) $ cConsoa .AND. Upper(Substr(cTexto,ni + 1,1)) $ cConsoa
				If lEncCon
					If Upper(Substr(cTexto,ni + 2,1)) $ "LR"
						lTritongo := .T.
					Else
						lTritongo := .F.
					Endif
				Else
					lTritongo := .F.
				Endif
				lEspaco	:= Upper(Substr(cTexto,ni,1)) $ cEspaco
				lConEsp	:= Upper(Substr(cTexto,ni,1)) $ cConsoa .AND. Upper(Substr(cTexto,ni + 1,1)) $ cEspaco
				//Palavra duas letras, que nao deve ser quebrada
				If ni > 2
					lPalDuas := Upper(Substr(cTexto,ni - 2,1)) $ cEspaco .AND. Upper(Substr(cTexto,ni,1)) $ (cConsoa + cVogais) .AND. ;
					Upper(Substr(cTexto,ni + 2,1)) $ (cEspaco + cPontua)
				Else
					lPalDuas := .F.
				Endif
				//Palavra tres letras, que nao deve ser quebrada
				If !lPalDuas .AND. ni > 2
					lPalTres := Upper(Substr(cTexto,ni - 2,1)) $ cEspaco .AND. Upper(Substr(cTexto,ni,1)) $ (cConsoa + cVogais) .AND. ;
					Upper(Substr(cTexto,ni + 1,1)) $ (cConsoa + cVogais) .AND. Upper(Substr(cTexto,ni + 2,1)) $ (cEspaco + cPontua)
				Else
					lPalTres := .F.
				Endif
				If nCont > nLimite .AND. ((!lPontua .AND. lUltVog .AND. !lEncVoc .AND. (!lEncCon .OR. lTritongo) .AND. !lConEsp .AND. !lPalDuas .AND. !lPalTres) .OR. (lEspaco))
					nCont := 0
					//Se nao for o ultimo caracter
					If ni < nTam
						//Se o caracter processado for uma consoante ou vogal e nao for um tritongo inserir o separador
						If Upper(Substr(cTexto,ni,1)) $ (cVogais + cConsoa)
							If lTritongo
								aRet[nPos] += Substr(cTexto,ni,1) + "-"
							Else
								aRet[nPos] += "-"
							Endif
						Endif
					Endif
					aAdd(aRet,"")
					nPos := Len(aRet)
				Else
					//Negar o tritongo, pois nao havera necessidade de quebra e a letra precisa ser adicionada
					lTritongo := .F.
				Endif
			Endif
			If !lTritongo
				aRet[nPos] += Substr(cTexto,ni,1)
			Endif
			nCont++
		Next ni
		For ni := 1 to Len(aRet)
			aRet[ni] := LTrim(aRet[ni])
		Next ni
	Else
		aRet[nPos] := cTexto
	Endif
	If lArray
		uRet := aClone(aRet)
	Else
		uRet := ""
		ni := 0
		aEval(aRet,{|x| ++ni,uRet += x + IIf(ni < Len(aRet),CRLF,"")})
	Endif

Return uRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณRtStartPathบAutor  ณPablo Gollan Carreras บ Data ณ27/07/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณRotina para retornar o startpath do ambiente em utilizacao        บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[L] : Determina se o separador de diretorios deve ser agre-  บฑฑ
ฑฑบ          ณ           gado no final do path.                                 บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณNenhum                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGENERICO                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function RtStartPath(lSepFin)

	Local cRet				:= ""
	Local cDirSep			:= IIf(IsSrvUnix(),"/","\")
	Local cEnvServ			:= GetEnvServer()
	Local cIniFile			:= GetADV97()
	Local cSPIni			:= RTrim(GetPvProfString(cEnvServ,"StartPath","",cIniFile))

	PARAMTYPE 0	VAR lSepFin		AS Logical		OPTIONAL	DEFAULT .F.

	cRet := IIf(Right(cSPIni,1) == cDirSep,Substr(cSPIni,1,RAt(cDirSep,cSPIni) - 1),cSPIni) + IIf(lSepFin,cDirSep,"")

Return cRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณLastAlias  บAutor  ณPablo Gollan Carreras บ Data ณ01/08/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณRotina para retornar o ultimo alias aberto na workarea            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[L] : Retornar tabela temporaria                             บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExp01[C] : Alias                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGENERICO                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function LastAlias(lTMP)

	Local cRet				:= ""
	Local ni				:= 0
	Local cAliasAt			:= ""

	PARAMTYPE 0	VAR lTMP		AS Logical		OPTIONAL	DEFAULT .F.

	For ni := 511 to 1 Step -1
		If !Empty(cAliasAt := Alias(ni))
			If lTMP
				If !AliasInDic(StrTran(cAliasAt,"_",""))
					cRet := cAliasAt
					Exit
				Endif
			Else
				cRet := cAliasAt
				Exit
			Endif
		Endif
	Next ni

Return cRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณRetTitId   บAutor  ณPablo Gollan Carreras บ Data ณ19/12/11        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณRotina para retornar titulo ou descricao de um campo do dicionarioบฑฑ
ฑฑบ          ณ                                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[C] : Nome do campo                                          บฑฑ
ฑฑบ          ณExp02[N] : Codigo do idioma                                       บฑฑ
ฑฑบ          ณExp03[L] : Retornar descricao do campo                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณ                                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGENERICO                                                          บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function RetTitId(cField,nIdioma,lDescr)

	Local cRet				:= ""
	Local cCampo			:= ""
	Local aAreaSX3			:= SX3->(GetArea())

	PARAMTYPE 0	VAR cField		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 1	VAR nIdioma		AS Numeric		OPTIONAL	DEFAULT 0
	PARAMTYPE 2 VAR lDescr		AS Logical		OPTIONAL	DEFAULT .F.

	If Empty(cField) .OR. !cValToChar(nIdioma) $ "0123"
		Return cRet
	Endif
	If Empty(nIdioma)
		#IFDEF SPANISH
		nIdioma := 2
		#ELSE
		#IFDEF ENGLISH
		nIdioma := 3
		#ELSE
		nIdioma := 1
		#ENDIF
		#ENDIF
	Endif
	dbSelectArea("SX3")
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(PadR(AllTrim(cField),10)))
		Do Case
			Case nIdioma == 1
			If !lDescr
				cCampo := "X3_TITULO"
			Else
				cCampo := "X3_DESCRIC"
			Endif
			Case nIdioma == 2
			If !lDescr
				cCampo := "X3_TITSPA"
			Else
				cCampo := "X3_DESCSPA"
			Endif
			Case nIdioma == 3
			If !lDescr
				cCampo := "X3_TITENG"
			Else
				cCampo := "X3_DESCENG"
			Endif
		EndCase
	Endif
	If !Empty(cCampo) .AND. SX3->(FieldPos(cCampo)) > 0
		cRet := AllTrim(SX3->&(cCampo))
	Endif
	RestArea(aAreaSX3)

Return cRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณRetAlias   บAutor  ณPablo Gollan Carreras บ Data ณ13/12/11        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณRotina para retornar o Alias de um determinado campo do SX3       บฑฑ
ฑฑบ          ณ                                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[C] : Nome do campo                                          บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณ                                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function RetAlias(cCampo)

	Local cAlias			:= ""
	Local aAreaSX3			:= IIf(Select("SX3") == 0,Array(0),SX3->(GetArea()))

	PARAMTYPE 0 VAR cCampo		AS Character	OPTIONAL DEFAULT ""

	If Empty(cCampo) .OR. Len(aAreaSX3) == 0
		Return cAlias
	Endif
	cCampo := StrTran(cCampo,"M->","")
	dbSelectArea("SX3")
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(PadR(AllTrim(cCampo),10)))
		cAlias := SX3->X3_ARQUIVO
	Endif
	RestArea(aAreaSX3)

Return cAlias

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณFecArTMP  บAutor  ณPablo Gollan Carreras บ Data ณ17/04/12     บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณRotina para encerrar alias e arquivos temporarios criados a   บฑฑ
ฑฑบ          ณpartir de uma query.                                          บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGenerico                                                      บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function FecArTMP(cAlias,lExTT,cTabTT)

	PARAMTYPE 0	VAR cAlias		AS Character				DEFAULT ""
	PARAMTYPE 1	VAR lExTT		AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 2	VAR cTabTT		AS Character	OPTIONAL	DEFAULT ""

	If Empty(cAlias)
		Return Nil
	Endif
	If Select(cAlias) > 0
		dbSelectArea(cAlias)
		dbCloseArea()
		If File(cAlias + OrdBagExt())
			fErase(cAlias + OrdBagExt())
		Endif
		If File(cAlias + GetDbExtension())
			fErase(cAlias + GetDbExtension())
		Endif
	Endif
	If lExTT .AND. !Empty(cTabTT) .AND. FindFunction("U_TTExcluir")
		If MsFile(cTabTT,,__cRDD)
			U_TTExcluir(cTabTT)
		Endif
	Endif

Return Nil

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณRtPicNum   บAutor  ณPablo Gollan Carreras บ Data ณ29/08/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณRotina para retornar uma picture de valor numerico de acordo com  บฑฑ
ฑฑบ          ณo tamanho do campo e o numero de casas decimais informados.       บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[N] : Tamanho do campo                                       บฑฑ
ฑฑบ          ณExp02[N] : Numero de casas decimais                               บฑฑ
ฑฑบ          ณExp03[L] : Formatar o numero em formato europeu                   บฑฑ
ฑฑบ          ณExp04[L] : Incluir separador de milhar                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExp01[C] : Mascara de formatacao elaborada de acordo com os param.บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGENERICO                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function RtPicNum(nCasas,nDecimais,lEuro,lSepM)

	Local cRet				:= ""
	Local ni				:= 0
	Local aForma			:= Array(2)
	Local nLimite			:= 0
	Local nCntM				:= 0
	Local cSepM				:= ","
	Local cSepD				:= "."

	PARAMTYPE 0	VAR nCasas		AS Numeric		OPTIONAL	DEFAULT 0
	PARAMTYPE 1	VAR nDecimais	AS Numeric		OPTIONAL	DEFAULT 0
	PARAMTYPE 2	VAR lEuro		AS Logical		OPTIONAL	DEFAULT .T.
	PARAMTYPE 3	VAR lSepM		AS Logical		OPTIONAL	DEFAULT .F.

	If Empty(nCasas) .OR. nCasas < nDecimais
		Return cRet
	Endif
	aFill(aForma,"")
	cRet := "@" + IIf(lEuro,"E","") + Space(1)
	nLimite := (nCasas - IIf(!Empty(nDecimais),1,0)) - nDecimais
	For ni := nLimite to 1 Step -1
		aForma[1] := "9" + aForma[1]
		If lSepM .AND. ++nCntM >= 3 .AND. ni # 1
			aForma[1] := cSepM + aForma[1]
			nCntM := 0
		Endif
	Next ni
	If !Empty(nDecimais)
		aForma[2] := cSepD + Replicate("9",nDecimais)
	Endif
	cRet += (aForma[1] + aForma[2])

Return cRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออออหออออออัอออออออออออออออออปฑฑ
ฑฑบPrograma  ณEnvEML    บAutor  ณPablo Gollan Carreras บ Data ณ25/04/12         บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออออสออออออฯอออออออออออออออออนฑฑ
ฑฑบDescricao ณFuncao de envio de e-mail utilizando as classe tMailManager e     บฑฑ
ฑฑบ          ณtMailMessage.                                                     บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[L] : Conexao SSL                                            บฑฑ
ฑฑบ          ณExp02[L] : Conexao TLS                                            บฑฑ
ฑฑบ          ณExp03[L] : Autenticar para envio                                  บฑฑ
ฑฑบ          ณExp04[C] : E-mail do remetente                                    บฑฑ
ฑฑบ          ณExp05[C] : E-mail de destino                                      บฑฑ
ฑฑบ          ณExp06[C] : E-mail com copia                                       บฑฑ
ฑฑบ          ณExp07[C] : E-mail com copia oculta                                บฑฑ
ฑฑบ          ณExp08[C] : Assunto (subject)                                      บฑฑ
ฑฑบ          ณExp09[C] : Mensagem (body)                                        บฑฑ
ฑฑบ          ณExp10[C] : Servidor SMTP                                          บฑฑ
ฑฑบ          ณExp11[C] : Senha da conta / usuario                               บฑฑ
ฑฑบ          ณExp12[C] : Porta do servidor SMTP (padrao 25)                     บฑฑ
ฑฑบ          ณExp13[C] : Nome do usuario (para autenticacao)                    บฑฑ
ฑฑบ          ณExp14[N] : Time-out                                               บฑฑ
ฑฑบ          ณExp15[L] : Gerar arquivo EML?                                     บฑฑ
ฑฑบ          ณExp16[L] : Mostrar mensagens de erro em tela?                     บฑฑ
ฑฑบ          ณExp17[L] : Tentar alternativas em falha de conexao?               บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGenerico                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ001        บAutor  ณPablo Gollan Carreras บ Data ณ07/12/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณNovo tratamento de erro. Tratamento para envio de anexos.         บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ002        บAutor  ณPablo Gollan Carreras บ Data ณ26/12/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ1.Inclusao de parametro para determinar se em caso de falha de    บฑฑ
ฑฑบ          ณ  de conexao, outras alternativas de config. devem ser utilizadas บฑฑ
ฑฑบ          ณ2.Inclusao de tentativa de autenticacao sem dominio em caso de    บฑฑ
ฑฑบ          ณ  falha de autenticacao de usuario.                               บฑฑ
ฑฑบ          ณ3.Inclusao de tratamento de copia de arquivo para anexar que sejamบฑฑ
ฑฑบ          ณ  de unidades mapeadas e nao do diretorio do servidor Protheus,   บฑฑ
ฑฑบ          ณ  pois arquivos que estejam fora do rootpath nao sao aceitos. In- บฑฑ
ฑฑบ          ณ  clusao de tratamento de erro e exclusao de arquivos temporarios.บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ003        บAutor  ณPablo Gollan Carreras บ Data ณ27/12/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณTratamento para contas de e-mails, como separadores, espacos, etc.บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function EnvEML(lSSL,lTLS,lAuth,cEmissor,cDest,cCC,cBCC,cAssunto,cMens,cServ,cPWD,nPorta,cUsuario,nTOUT,lGeraArq,aAnexo,lMostraMsg,lTentaAlt)

	Local lRet				:= .T.
	Local cPath 			:= ""
	Local nPos				:= 0
	Local nStatusCode 		:= 0
	Local MailServer 		:= tMailManager():New()
	Local MailMessage 		:= tMailMessage():New()
	Local cRotina			:= ExecBlock("RtFunName",.F.,.F.,{.F.,.T.})
	Local bMensFim			:= {|| ConOut(cRotina + "Finalizado " + Time())}
	Local bProcMsg			:= {|cTexto,lMF,lOff| ConOut(cRotina + cTexto),IIf(lMostraMsg .AND. !IsBlind(),MsgStop(cTexto,cRotina),.T.),IIf(ValType(lMF) == "L" .AND. lMF,Eval(bMensFim),.T.)}
	Local ni				:= 0
	Local cDirSep			:= IIf(IsSrvUnix(),"/","\")
	Local cDirStart			:= IIf(Right(RTrim(GetSrvProfString("StartPath","")),1) == cDirSep,RTrim(GetSrvProfString("StartPath","")),RTrim(GetSrvProfString("StartPath","")) + cDirSep)
	Local aAnexoT			:= {}
	Local cDrive			:= ""
	Local cDir				:= ""
	Local cArqP				:= ""
	Local cExt				:= ""
	Local cArqD				:= ""
	Local bTrataEml			:= {|cEndEml| StrTran(StrTran(Lower(AllTrim(cEndEml)),",",";")," ",";")}

	PARAMTYPE 0		VAR lSSL		AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 1		VAR lTLS		AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 2		VAR lAuth		AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 3		VAR cEmissor	AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 4		VAR cDest		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 5		VAR cCC			AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 6		VAR cBCC		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 7		VAR cAssunto	AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 8		VAR cMens		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 9		VAR cServ		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 10	VAR cPWD		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 11	VAR nPorta		AS Numeric		OPTIONAL	DEFAULT 25
	PARAMTYPE 12	VAR cUsuario	AS Character	OPTIONAL	DEFAULT cEmissor
	PARAMTYPE 13	VAR nTOUT		AS Numeric		OPTIONAL	DEFAULT 30
	PARAMTYPE 14	VAR lGeraArq	AS Logical		OPTIONAL	DEFAULT .T.
	PARAMTYPE 15	VAR aAnexo		AS Array		OPTIONAL	DEFAULT Array(0)
	PARAMTYPE 16	VAR lMostraMsg	AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 17	VAR lTentaAlt	AS Logical		OPTIONAL	DEFAULT .F.

	ConOut(cRotina + "Iniciando " + Time())
	If Empty(cEmissor) .OR. Empty(cDest) .OR. Empty(cServ) .OR. Empty(cPWD)
		Eval(bProcMsg,"Falha no envio da mensagem SMTP por inconsistencia nos parametros.",.T.)
		Return !lRet
	Endif
	ConOut(cRotina + "Servidor : " + cServ)
	ConOut(cRotina + "Usuario : " + cUsuario)
	ConOut(cRotina + "Senha : " + cPWD)
	ConOut(cRotina + "Porta : " + AllTrim(AllToChar(nPorta)))
	ConOut(cRotina + "TLS : " + IIf(lTLS,"S","N"))
	ConOut(cRotina + "SSL : " + IIf(lSSL,"S","N"))
	If lGeraArq
		cPath	:= GetSrvProfString("RootPath","")
		cPath 	+= IIf(!(Left(cPath,1) == cDirSep),cDirSep,"")
	Endif
	//Redefine a chave Protocol com o valor POP3 na se็ใo Mail
	WritePProString("Mail","Protocol","POP3",GetSrvIniName())
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณDefine o servidor de e-mails  ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	If lSSL
		MailServer:SetUseSSL(.T.)
	ElseIf lTLS
		MailServer:SetUseTLS(.T.)
	Endif
	nStatusCode := MailServer:Init("",cServ,cUsuario,cPWD,0,nPorta)
	If nStatusCode # 0
		Eval(bProcMsg,MailServer:GetErrorString(nStatusCode),.T.)
		Return !lRet
	Endif
	MailServer:SetSMTPTimeout(nTOUT)
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณConecta com o servidor de e-mails  ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	ConOut(cRotina + "Tentando conexao usuario " + cUsuario)
	nStatusCode := MailServer:SMTPConnect()
	If nStatusCode # 0
		ConOut(cRotina + MailServer:GetErrorString(nStatusCode))
		//Desconectar
		MailServer:SMTPDisconnect()
		//Tratamento de tentativas alternativas de conexao em caso de falha
		If lTentaAlt
			If lSSL
				//Se o SSL estiver ativo, tentar a conexao sem SSL
				MailServer:SetUseSSL(.F.)
				nStatusCode := MailServer:SMTPConnect()
			Endif
			If lTLS
				//Se o TLS estiver ativo, tentar a conexao sem SSL
				MailServer:SetUseSSL(.F.)
				nStatusCode := MailServer:SMTPConnect()
			Endif
			//Se o usuario possuir @, tentar conectar sem
			If nStatusCode # 0
				If (nPos := At("@",cUsuario)) > 0
					cUsuario := Substr(cUsuario,1,nPos - 1)
					nStatusCode := MailServer:Init("",cServ,cUsuario,cPWD,,nPorta)
					If nStatusCode # 0
						Eval(bProcMsg,MailServer:GetErrorString(nStatusCode),.T.)
						Return !lRet
					Endif
					ConOut(cRotina + "Tentando conexao usuario " + cUsuario)
					nStatusCode := MailServer:SMTPConnect()
				Else
					cUsuario := cEmissor
					nStatusCode := MailServer:Init("",cServ,cUsuario,cPWD,,nPorta)
					If nStatusCode # 0
						Eval(bProcMsg,MailServer:GetErrorString(nStatusCode),.T.)
						Return !lRet
					Endif
					ConOut(cRotina + "Tentando conexao usuario " + cUsuario)
					nStatusCode := MailServer:SMTPConnect()
				Endif
			Endif
		Endif
		If nStatusCode # 0
			Eval(bProcMsg,MailServer:GetErrorString(nStatusCode),.T.)
			//Desconectar
			MailServer:SMTPDisconnect()
			If lGeraArq
				MailMessage:Clear()
				MailMessage:cFrom		:= cEmissor
				MailMessage:cTo			:= Eval(bTrataEml,cDest)
				MailMessage:cCC			:= Eval(bTrataEml,cCC)
				MailMessage:cBcc		:= Eval(bTrataEml,cBCC)
				MailMessage:cSubject	:= cAssunto
				MailMessage:cBody		:= cMens
				MailMessage:Save(cPath + "mensagem.eml")
			Endif
			Return !lRet
		Endif
	Endif
	//O servidor de e-mails requer autentica็ใo
	If lAuth
		nStatusCode := MailServer:SMTPAuth(cUsuario,cPWD)
		//Se o usuario possuir @, tentar conectar sem
		If nStatusCode # 0
			If (nPos := At("@",cUsuario)) > 0
				cUsuario := Substr(cUsuario,1,nPos - 1)
				nStatusCode := MailServer:Init("",cServ,cUsuario,cPWD,,nPorta)
				If nStatusCode # 0
					Eval(bProcMsg,MailServer:GetErrorString(nStatusCode),.T.)
					Return !lRet
				Endif
				ConOut(cRotina + "Tentando conexao usuario " + cUsuario)
				If (nStatusCode := MailServer:SMTPConnect()) == 0
					nStatusCode := MailServer:SMTPAuth(cUsuario,cPWD)
				Else
					Eval(bProcMsg,MailServer:GetErrorString(nStatusCode),.T.)
				Endif
			Else
				cUsuario := cEmissor
				nStatusCode := MailServer:Init("",cServ,cUsuario,cPWD,,nPorta)
				If nStatusCode # 0
					Eval(bProcMsg,MailServer:GetErrorString(nStatusCode),.T.)
					Return !lRet
				Endif
				ConOut(cRotina + "Tentando conexao usuario " + cUsuario)
				If (nStatusCode := MailServer:SMTPConnect()) == 0
					nStatusCode := MailServer:SMTPAuth(cUsuario,cPWD)
				Else
					Eval(bProcMsg,MailServer:GetErrorString(nStatusCode),.T.)
				Endif
			Endif
		Endif
		If nStatusCode # 0
			Eval(bProcMsg,MailServer:GetErrorString(nStatusCode),.T.)
			//Desconectar
			MailServer:SMTPDisconnect()
			Return !lRet
		Endif
	Endif
	MailMessage:Clear()
	MailMessage:cFrom		:= cEmissor	//Conta SMTP
	MailMessage:cTo			:= Eval(bTrataEml,cDest)
	MailMessage:cCC			:= Eval(bTrataEml,cCC)
	MailMessage:cBcc		:= Eval(bTrataEml,cBCC)
	MailMessage:cSubject	:= cAssunto
	MailMessage:cBody		:= cMens
	//ฺฤฤฤฤฤฤฤฟ
	//ณAnexo  ณ
	//ภฤฤฤฤฤฤฤู
	For ni := 1 to Len(aAnexo)
		If ValType(aAnexo[ni]) == "C" .AND. File(aAnexo[ni])
			//Caso o arquivo nao esteja no servidor, copiar para anexar e excluir apos o envio da mensagem
			If Empty(At(":",aAnexo[ni]))
				If MailMessage:AttachFile(aAnexo[ni]) < 0
					Eval(bProcMsg,"Erro ao tentar anexar o arquivo [" + aAnexo[ni] + "]")
					//Desconectar
					MailServer:SMTPDisconnect()
					Return !lRet
				Endif
			Else
				//Identificar nome e extensao do arquivo
				SplitPath(aAnexo[ni],@cDrive,@cDir,@cArqP,@cExt)
				cArqD := cDirStart + cArqP + cExt
				//Copiar para o servidor e validar arquivo
				If CpyT2S(aAnexo[ni],cDirStart,.F.) .AND. File(cArqD)
					aAdd(aAnexoT,cArqD)
					//Anexar o arquivo temporario
					If MailMessage:AttachFile(cArqD) < 0
						Eval(bProcMsg,"Erro ao tentar anexar o arquivo [" + cArqD + "]")
						aEval(aAnexoT,{|x| IIf(fErase(x) == 0,.T.,Eval(bProcMsg,fError()))})
						//Desconectar
						MailServer:SMTPDisconnect()
						Return !lRet
					Endif
				Else
					Eval(bProcMsg,"Erro ao tentar anexar o arquivo [" + aAnexo[ni] + "] c๓pia mal sucedida para [" + cDirStart + cArqP + cExt + "]")
					aEval(aAnexoT,{|x| IIf(fErase(x) == 0,.T.,Eval(bProcMsg,fError()))})
					//Desconectar
					MailServer:SMTPDisconnect()
					Return !lRet
				Endif
			Endif
		Endif
	Next ni
	//ฺฤฤฤฤฤฤฤฤฟ
	//ณSalvar  ณ
	//ภฤฤฤฤฤฤฤฤู
	If lGeraArq
		MailMessage:Save(IIf(lSSL,cPath,cPath) + "mensagem.eml")
	Endif
	//ฺฤฤฤฤฤฤฤฤฟ
	//ณEnviar  ณ
	//ภฤฤฤฤฤฤฤฤู
	nStatusCode := MailMessage:Send(MailServer)
	If nStatusCode # 0
		Eval(bProcMsg,MailServer:GetErrorString(nStatusCode))
		lRet := !lRet
	Else
		Eval(bProcMsg,"E-mail enviado com sucesso!")
	Endif
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณDesconecta  ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤู
	MailServer:SMTPDisconnect()
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณApagar arquivos temporarios  ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	aEval(aAnexoT,{|x| IIf(fErase(x) == 0,.T.,Eval(bProcMsg,fError()))})
	Eval(bMensFim)

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออออหออออออัอออออออออออออออออปฑฑ
ฑฑบPrograma  ณVlCfgEml  บAutor  ณPablo Gollan Carreras บ Data ณ07/12/12         บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออออสออออออฯอออออออออออออออออนฑฑ
ฑฑบDescricao ณValida configuracoes de SMTP e retorna parametros para envio      บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[L] : Capturar email                                         บฑฑ
ฑฑบ          ณExp02[L] : Mostrar mensagem de erro                               บฑฑ
ฑฑบ          ณExp03[C] : Email sugerido                                         บฑฑ
ฑฑบ          ณExp04[C] : Titulo da rotina                                       บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGENERICO                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ001        บAutor  ณPablo Gollan Carreras บ Data ณ27/12/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณInclusao de tratamento para aceitar o email sugerido              บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ002        บAutor  ณPablo Gollan Carreras บ Data ณ27/12/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณUtilizacao do include VlCfgEml para identificacao de pos. retorno บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function VlCfgEml(lCapEml,lMens,cEmlSugere,cTitRot)

	Local oArea				:= FWLayer():New()
	Local aCoord			:= FWGetDialogSize(oMainWnd)
	Local aTamObj			:= Array(4)
	Local nCoefDif			:= 1
	Local aRet				:= Array(10)
	Local cSMTPUsu			:= ""
	Local cContaEml			:= ""
	Local cEmlTo			:= ""
	Local cServ				:= ""
	Local nPorta			:= ""
	Local cPWD				:= ""
	//Local cSMTPAut			:= ""
	Local lTLS				:= .F.
	Local lSSL				:= .F.
	Local nTOUT				:= 0
	Local nPos				:= 0
	Local ni				:= 0
	Local nTamMax			:= 150
	Local cEmail			:= Space(nTamMax)
	Local cTMP				:= ""
	Local aLstPar			:= {"MV_RELAUSR","MV_RELACNT","MV_RELSERV","MV_RELPSW","MV_RELAUTH","MV_RELTLS","MV_RELTIME","MV_RELSSL","MV_GCPPORT"}
	Local cRotina			:= ExecBlock("RtFunName",.F.,.F.,{.F.,.T.}) + Space(1)
	Local cEtq01			:= OemToAnsi("Digite o e-mail de destino : ")
	Local nOpcA				:= 0
	//Objetos graficos
	Local oTela
	Local oPainel01
	Local oPainel02
	Local oBot01
	Local oBot02

	PARAMTYPE 0	VAR lCapEml		AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 1	VAR lMens		AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 2	VAR cEmlSugere	AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 3	VAR cTitRot		AS Character	OPTIONAL	DEFAULT "Envio de e-mail"

	cSMTPUsu 	:= RTrim(SuperGetMV("MV_RELAUSR",.F.,""))
	cContaEml	:= RTrim(IIf(!Empty(cTMP := SuperGetMV("MV_RELACNT",.F.,"")),cTMP,SuperGetMV("MV_RELFROM",.F.,"")))
	cServ 		:= RTrim(SuperGetMV("MV_RELSERV",.F.,""))
	cPWD		:= RTrim(SuperGetMV("MV_RELPSW",.F.,""))
	lSMTPAut	:= SuperGetMV("MV_RELAUTH",.F.,.F.)
	lTLS		:= SuperGetMV("MV_RELTLS",.F.,.F.)
	lSSL		:= SuperGetMV("MV_RELSSL",.F.,.F.)
	nTOUT		:= SuperGetMV("MV_RELTIME",.F.,120)
	cEmlSugere	:= PadR(cEmlSugere,nTamMax)
	cEmail		:= cEmlSugere
	If Empty(cSMTPUsu)
		cSMTPUsu := cContaEml
	Endif
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณValidar parametros  ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	If Empty(cContaEml) .OR. Empty(cServ) .OR. Empty(cPWD) .OR. Empty(cContaEml) .OR. Empty(cSMTPUsu)
		ConOut(cRotina + "Configuracao de conta de e-mail para uso de SMTP invalida.")
		ConOut(cRotina + "Parametros necessarios : ")
		For ni := 1 to Len(aLstPar)
			ConOut(cRotina + aLstPar[ni] + " - " + AllToChar(GetMV(aLstPar[ni])))
		Next ni
		If lMens
			cTMP := "Configuracao de conta de e-mail para uso de SMTP invalida." + CRLF
			cTMP += "Parametros necessarios : " + CRLF
			For ni := 1 to Len(aLstPar)
				If aLstPar[ni] == "MV_RELPSW"
					cTMP += "- " + aLstPar[ni] + " - " + Embaralha(AllTrim(AllToChar(GetMV(aLstPar[ni]))),1) + CRLF
				Else
					cTMP += "- " + aLstPar[ni] + " - " + AllTrim(AllToChar(GetMV(aLstPar[ni]))) + CRLF
				Endif
			Next ni
			MsgStop(cTMP,cRotina)
		Endif
		Return Array(0)
	Endif
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณCapturar de validar conta de email  ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	If lCapEml
		If FindFunction("U_ApRedFWL") .AND. U_ApRedFWL(.T.)
			nCoefDif := 0.95
		Endif
		aCoord[3] := aCoord[3] * 0.3
		aCoord[4] := aCoord[4] * 0.6

		oTela := tDialog():New(aCoord[1],aCoord[2],aCoord[3],aCoord[4],OemToAnsi(cTitRot),,,,,/*nClrText*/,/*nClrBack*/,,,.T.)

		oArea:Init(oTela,.F.)
		//PAINEIS
		oArea:AddLine("L01",100 * nCoefDif,.T.)
		oArea:AddCollumn("L01C01",080,.F.,"L01")
		oArea:AddCollumn("L01C02",020,.F.,"L01")
		oArea:AddWindow("L01C01","L01C01P01","Digite o(s) e-mail(s) desejados :",100,.F.,.F.,/*bAction*/,"L01",/*bGotFocus*/)
		oPainel01 := oArea:GetWinPanel("L01C01","L01C01P01","L01")
		oArea:AddWindow("L01C02","L01C02P01","Fun็๕es",100,.F.,.F.,/*bAction*/,"L01",/*bGotFocus*/)
		oPainel02 := oArea:GetWinPanel("L01C02","L01C02P01","L01")
		//CAMPO DIGITACAO
		aTamObj[1] := 001
		aTamObj[2] := 001
		aTamObj[3] := (oPainel01:nWidth / 2) - (nDistAPad * 2)
		aTamObj[4] := nAltEtq
		oEtq01 := tSay():New(aTamObj[1],aTamObj[2],&("{|| '" + cEtq01 + "'}"),oPainel01,/*pict*/,/*fonte*/,,,,.T.,,,aTamObj[3],aTamObj[4])
		aTamObj[1] := aTamObj[1] + nAltEtq + nDistPad
		aTamObj[4] := nAltCont
		oEmail := tGet():New(aTamObj[1],aTamObj[2],{|x| IIf(PCount() > 0,cEmail := x,cEmail)},oPainel01,aTamObj[3],aTamObj[4],"",;
		{|| AllwaysTrue()}/*Valid*/,/*FColor*/,/*BColor*/,/*font*/,,,.T.,,,/*when*/,,,{|| }/*change*/,/*Read*/,.F./*Pwd*/,,"cEmail")
		oEmail:oJump := oBot01
		//ฺฤฤฤฤฤฤฤฤฤฟ
		//ณFuncoes  ณ
		//ภฤฤฤฤฤฤฤฤฤู
		aTamObj[1] := 000
		aTamObj[2] := 000
		aTamObj[3] := oPainel02:nClientWidth / 2
		aTamObj[4] := nAltBot
		oBot01 := tButton():New(aTamObj[1],aTamObj[2],cHK + "Confirmar",oPainel02,;
		{|| IIf(!Empty(cEmail) .AND. Len(cEmail) >= 6 .AND. !Empty(At("@",cEmail)),(nOpcA := 1,oTela:End()),.F.)},aTamObj[3],aTamObj[4],,/*oFont*/,,.T.,,,,/*bWhen*/)
		aTamObj[1] := aTamObj[1] + nAltBot + nDistPad
		oBot02 := tButton():New(aTamObj[1],aTamObj[2],"C" + cHK + "ancelar",oPainel02,{|| oTela:End()},aTamObj[3],aTamObj[4],,/*oFont*/,,.T.,,,,/*bWhen*/)

		oTela:Activate(,,,.T.,/*valid*/,,{|| oEmail:SetFocus()})

		If Empty(nOpcA)
			Return Array(0)
		Endif
		cEmlTo := cEmail
	Endif
	//Separar servidor x porta
	If (nPos := RAt(":",cServ)) > 0 .AND. !Empty(Substr(cServ,nPos + 1,Len(cServ)))
		nPorta := GetDToVal(Substr(cServ,nPos + 1,Len(cServ)))
		cServ := Substr(cServ,1,nPos - 1)
	Else
		nPorta := SuperGetMV("MV_GCPPORT",.F.,25)
	Endif
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณEstrutura de retorno :                            ณ
	//ณ================================================  ณ
	//ณ01 - Conta SMTP                                   ณ
	//ณ02 - Usuario                                      ณ
	//ณ03 - Senha                                        ณ
	//ณ04 - Servidor                                     ณ
	//ณ05 - Porta                                        ณ
	//ณ06 - Autentica SMTP                               ณ
	//ณ07 - TLS                                          ณ
	//ณ08 - Timeout                                      ณ
	//ณ09 - Email destino                                ณ
	//ณ10 - SSL                                          ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	aRet[P_EML_FROM]	:= cContaEml
	aRet[P_EML_USER]	:= cSMTPUsu
	aRet[P_EML_PWD]		:= cPWD
	aRet[P_EML_SERV]	:= cServ
	aRet[P_EML_PORT]	:= nPorta
	aRet[P_EML_AUTH] 	:= lSMTPAut
	aRet[P_EML_TLS]		:= lTLS
	aRet[P_EML_TOUT]	:= nTOUT
	aRet[P_EML_TO]		:= cEmlTo
	aRet[P_EML_SSL]		:= lSSL

Return aRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณPesquisa   บAutor  ณPablo Gollan Carreras บ Data ณ16/02/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณFuncao para execucao de query de pesquisa, devolvendo os dados    บฑฑ
ฑฑบ          ณformatados. Para busca de tab. unica c/ campos fora de indices.   บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[N] : Nome da tabela                                         บฑฑ
ฑฑบ          ณExp02[A] : Lista de campos a retornar                             บฑฑ
ฑฑบ          ณExp03[C] : Clausula de restricao                                  บฑฑ
ฑฑบ          ณExp04[N] : Indice de ordenacao de dados                           บฑฑ
ฑฑบ          ณExp05[L] : Formatar dados                                         บฑฑ
ฑฑบ          ณExp06[L] : Utilizar agrupamento                                   บฑฑ
ฑฑบ          ณExp07[L] : Nao utilizar filial no filtro                          บฑฑ
ฑฑบ          ณExp08[L] : Considerar registros deletados                         บฑฑ
ฑฑบ          ณExp09[C] : Ordenacao de registros customizada.                    บฑฑ
ฑฑบ          ณExp10[C] : Determina que o resultado nao deve retornar como array บฑฑ
ฑฑบ          ณ           valido apenas para pesquisa com 1 campo e retorna ape- บฑฑ
ฑฑบ          ณ           nas o conteudo do primeiro registro encontrado.        บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณ                                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGenerico                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ001        บAutor  ณPablo Gollan Carreras บ Data ณ20/07/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณInclusao de tratamento da clausula DISTINCT para campos que uti-  บฑฑ
ฑฑบ          ณlizam funcoes aglutinadoras, como o COUNT.                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function Pesquisa(cTabela,aLstCmp,cRestricao,nIndice,lFormata,lAgrupar,lNUsaFil,lUsaDel,cOrder,lNRetArr,lDistinct)

	Local aRet				:= {}
	Local cQry				:= ""
	Local cAliasT			:= GetNextAlias()
	Local lTop				:= .T.
	Local ni				:= 0
	Local nPos				:= 0
	Local aArea				:= {}
	Local aEstru			:= {}
	Local aTMP				:= {}
	Local aFuncAgl			:= {"SUM","COUNT","AVG","MIN","MAX"}						//Funcoes de aglutinacao
	Local lExCmpNAgl		:= .F.														//Existem campos de retorno que nao sao de aglutinacao?
	Local cCriterio			:= ""
	Local lTabSX2			:= .T.														//Tabela do dicionario de dados
	Local lIncDist			:= .F.														//Incluir a clausula DISTINCT dentro da funcao de aglutinacao
	Local cTMP				:= ""

	PARAMTYPE 0	 VAR cTabela	AS Character				DEFAULT ""
	PARAMTYPE 1	 VAR aLstCmp	AS Array					DEFAULT {}
	PARAMTYPE 2	 VAR cRestricao	AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 3	 VAR nIndice	AS Numeric		OPTIONAL	DEFAULT 1
	PARAMTYPE 4	 VAR lFormata	AS Logical		OPTIONAL	DEFAULT .T.
	PARAMTYPE 5  VAR lAgrupar	AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 6	 VAR lNUsaFil	AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 7	 VAR lUsaDel	AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 8	 VAR cOrder		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 9	 VAR lNRetArr	AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 10 VAR lDistinct	AS Logical		OPTIONAL	DEFAULT .F.

	#IFNDEF TOP
	If TcIsConnected()
		lTop := !lTop
	Endif
	#ENDIF
	lTabSX2 := Len(cTabela) == 3 .AND. AliasInDic(cTabela)
	If !lTop .OR. Empty(cTabela) .OR. (lTabSX2 .AND. Len(cTabela) # 3) .OR. Len(aLstCmp) == 0
		Return aRet
	Endif
	If lNRetArr .AND. Len(aLstCmp) # 1
		lNRetArr := !lNRetArr
	Endif
	If lTabSX2
		If Select(cTabela) == 0
			dbSelectArea(cTabela)
			(cTabela)->(dbSetOrder(1))
		Endif
		aArea 	:= (cTabela)->(GetArea())
		aEstru	:= (cTabela)->(dbStruct())
		dbSelectArea(cTabela)
		(cTabela)->(dbSetOrder(nIndice))
	Endif
	For ni := 1 to Len(aLstCmp)
		//Caso entre os campos a listar exista alguma funcao de aglutinacao, acionar a condicao de agrupamento
		If aScan(aFuncAgl,{|x| At(x + "(",Upper(aLstCmp[ni])) > 0 .OR. At(x + " (",Upper(aLstCmp[ni])) > 0}) > 0
			lAgrupar := .T.
		Else
			lExCmpNAgl := .T.
		Endif
	Next ni
	cQry := "SELECT "
	If lDistinct
		If lAgrupar .AND. !lExCmpNAgl
			lIncDist := .T.
		Else
			cQry += IIf(lDistinct,"DISTINCT ","")
		Endif
	Endif
	For ni := 1 to Len(aLstCmp)
		If lIncDist .AND. !Empty(nPos := aScan(aFuncAgl,{|x| At(x + "(",Upper(aLstCmp[ni])) > 0 .OR. At(x + " (",Upper(aLstCmp[ni])) > 0})) .AND. ;
		At("DISTINCT",aFuncAgl[nPos]) == 0

			cTMP := aFuncAgl[nPos] + "(DISTINCT "
			cTMP := StrTran(StrTran(aLstCmp[ni],aFuncAgl[nPos] + "(",cTMP),aFuncAgl[nPos] + " (",cTMP)
			cQry += cTMP
		Else
			cQry += aLstCmp[ni]
		Endif
		cQry += IIf(ni < Len(aLstCmp),", "," ")
	Next ni
	If lTabSX2
		cQry += "FROM " + RetSQLName(cTabela) + " "
	Else
		cQry += "FROM " + AllTrim(cTabela) + " "
	Endif
	If !lUsaDel
		cCriterio += "D_E_L_E_T_ <> '*' "
	Endif
	If !lNUsaFil
		cCriterio += "AND " + IIf(Substr(cTabela,1,1) == "S",Substr(cTabela,2,2),cTabela) + "_FILIAL = '" + xFilial(cTabela) + "' "
	Endif
	cCriterio += IIf(!Empty(cRestricao),IIf(!Empty(cCriterio),"AND ","") + cRestricao,"")
	If !Empty(cCriterio)
		cQry += "WHERE " + cCriterio + " "
	Endif
	//Tratamento de agrupamento
	If lAgrupar .AND. lExCmpNAgl
		cQry += "GROUP BY "
		//Considerar apenas os campos que nao se utilizam de formulas de aglutinacao
		For ni := 1 to Len(aLstCmp)
			If aScan(aFuncAgl,{|x| At(x,Upper(aLstCmp[ni])) > 0}) == 0
				cQry += aLstCmp[ni] + IIf(ni < Len(aLstCmp),","," ")
			Endif
		Next ni
		If Right(cQry,1) == ","
			cQry := Substr(cQry,1,Len(cQry) - 1) + " "
		Endif
	Endif
	If Empty(cOrder)
		If lTabSX2
			If !lAgrupar
				cQry += "ORDER BY " + StrTran((cTabela)->(IndexKey()),"+"," ASC, ") + " ASC"
			Endif
		Endif
	Else
		cQry += "ORDER BY " + cOrder
	Endif
	dbUseArea(.T.,__cRDD,TcGenQry(,,cQry),cAliasT,.T.,.F.)
	If lFormata .AND. lTabSX2
		For ni := 1 to (cAliasT)->(FCount())
			If (nPos := aScan(aEstru,{|x| Upper(AllTrim(x[1])) == Upper(AllTrim((cAliasT)->(FieldName(ni))))})) > 0
				If aEstru[nPos][2] # "C"
					TcSetField(cAliasT,(cAliasT)->(FieldName(ni)),aEstru[nPos][2],aEstru[nPos][3],aEstru[nPos][4])
				Endif
			Endif
		Next ni
	Endif
	(cAliasT)->(dbGoTop())
	If !(cAliasT)->(Eof())
		Do While !(cAliasT)->(Eof())
			If !lNRetArr
				aTMP := Array((cAliasT)->(FCount()))
				For ni := 1 to Len(aTMP)
					aTMP[ni] := (cAliasT)->(FieldGet(ni))
				Next ni
				aAdd(aRet,aTMP)
			Else
				aRet := (cAliasT)->(FieldGet(1))
				Exit
			Endif
			(cAliasT)->(dbSkip())
		EndDo
	Else
		If lNRetArr
			If lTabSX2 .AND. !Empty(Posicione("SX3",2,PadR((cAliasT)->(FieldName(1)),10),"X3_CAMPO"))
				aRet := CriaVar((cAliasT)->(FieldName(1)),.F.)
			Endif
		Endif
	Endif
	U_FecArTMP(cAliasT)
	If lTabSX2
		RestArea(aArea)
	Endif

Return aRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณExTelaMen  บAutor  ณPablo Gollan Carreras บ Data ณ03/02/2012      บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณRotina para montar uma tela para apresentacao de mensagem         บฑฑ
ฑฑบ          ณ                                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[C] : Titulo da janela                                       บฑฑ
ฑฑบ          ณExp02[C] : Texto a ser apresentado                                บฑฑ
ฑฑบ          ณExp03[C] : Nome da fonte                                          บฑฑ
ฑฑบ          ณExp04[N] : Tamanho da fonte                                       บฑฑ
ฑฑบ          ณExp05[L] : Dar foco no botao fechar                               บฑฑ
ฑฑบ          ณExp06[L] : Dar foco no botao cancelar                             บฑฑ
ฑฑบ          ณExp07[L] : Exibir a combinacao de botoes : OK e Cancelar          บฑฑ
ฑฑบ          ณExp08[C] : Acao a ser executada pelo Timer da rotina (opcional)   บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณ                                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGenerico                                                          บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function ExTelaMen(cTitulo,cTexto,cFonte,nTamFonte,lFocoFec,lFocoCanc,lOkCanc,cAcaoTimer)

	Local lRet				:= .T.
	Local aCoord			:= FWGetDialogSize(oMainWnd)
	Local aTamObj			:= Array(4)
	Local nCoefDif			:= 1
	//Local cLOGArq			:= ""
	Local cTipoArq    		:= "Arquivos Texto (*.TXT) |*.txt|"
	Local cAcao				:= "oMemo:SetFocus()"
	//Local cGET01
	//Local cGET02
	Local bAcao01			:= {|| }
	Local bAcao02			:= {|| }
	//Objetos graficos
	//Local oDlg
	//Local oEtq01
	Local oFont
	Local oTimerTE

	Private oMemo
	Private oBot01
	Private oBot02

	PARAMTYPE 0 VAR cTitulo		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 1 VAR cTexto		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 2 VAR cFonte		AS Character	OPTIONAL	DEFAULT "Mono AS"
	PARAMTYPE 3 VAR nTamFonte	AS Numeric		OPTIONAL	DEFAULT 0
	PARAMTYPE 4	VAR lFocoFec	AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 5	VAR lFocoCanc	AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 6	VAR lOkCanc		AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 7	VAR cAcaoTimer	AS Character	OPTIONAL	DEFAULT ""

	If lFocoFec .OR. lFocoCanc
		cAcao := "oBot02:SetFocus()"
	Endif
	oFont := tFont():New(cFonte,,IIf(!Empty(nTamFonte),Abs(nTamFonte),8) * -1,.T.)
	If FindFunction("U_ApRedFWL") .AND. U_ApRedFWL(.F.)
		nCoefDif := 0.95
	Endif
	aCoord[3] := aCoord[3] * 0.6
	aCoord[4] := aCoord[4] * 0.4
	DEFINE MSDIALOG oTela TITLE cTitulo FROM aCoord[1],aCoord[2] To aCoord[3],aCoord[4] PIXEL

	aTamObj[1] := 005
	aTamObj[2] := 005
	aTamObj[3] := (oTela:nWidth / 2) - aTamObj[2] * 2
	aTamObj[4] := ((oTela:nHeight * nCoefDif) / 2) - ((aTamObj[1] * 2) + nDistAPad + nAltBot + aTamObj[1])
	oMemo := tMultiGet():New(aTamObj[1],aTamObj[2],{|x| IIf(PCount() > 0,cTexto := x,cTexto)},oTela,aTamObj[3],aTamObj[4],oFont,.T.,,,,.T.,,,{|| .T.},,,.T.,/*bValid*/,,,.F.,.F.)
	oMemo:bRClicked := {|| AllwaysTrue()}
	If !lOkCanc
		bAcao01	:= {|| cArqLOG := cGetFile(cTipoArq,""),IIf(Empty(cArqLOG),.T.,MemoWrite(cArqLOG,cTexto))}
		bAcao02	:= {|| oTela:End()}
		cTAG01	:= "Gravar"
		cTAG02	:= "Fechar"
	Else
		bAcao01	:= {|| lRet := .T.,oTela:End()}
		bAcao02	:= {|| lRet := .F.,oTela:End()}
		cTAG01	:= "Ok"
		cTAG02	:= "Cancelar"
	Endif
	aTamObj[1] := ((oMemo:nTop + oMemo:nHeight) / 2) + nDistAPad
	aTamObj[2] := 005
	aTamObj[3] := ((oTela:nWidth / 2) - ((aTamObj[2] * 2) + nDistAPad)) / 2
	aTamObj[4] := nAltBot
	oBot01 := tButton():New(aTamObj[1],aTamObj[2],cHK + cTAG01,oTela,bAcao01,aTamObj[3],aTamObj[4],,/*Font*/,,.T.,,,,{|| .T.}/*When*/)
	aTamObj[2] := ((oBot01:nLeft + oBot01:nWidth) / 2) + nDistAPad
	oBot02 := tButton():New(aTamObj[1],aTamObj[2],cHK + cTAG02,oTela,bAcao02,aTamObj[3],aTamObj[4],,/*Font*/,,.T.,,,,{|| .T.}/*When*/)
	If !Empty(cAcaoTimer)
		oTimerTE := tTimer():New(3000,&("{|| " + cAcaoTimer + "}"),oTela)
		oTimerTE:Activate()
	Endif

	oTela:Activate(,,,.T.,/*valid*/,,&("{|| " + cAcao + "}"))

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณMntHTMCb   บAutor  ณPablo Gollan Carreras บ Data ณ25/05/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณMonta um cabecalho de um arquivo HTML                             บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[C] : Titulo do arquivo                                      บฑฑ
ฑฑบ          ณExp02[C] : Link do logo da empresa ou o desejado                  บฑฑ
ฑฑบ          ณExp03[L] : Imprimir dados da empresa                              บฑฑ
ฑฑบ          ณExp04[L] : Imprimir linha de quebra                               บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณcCabec[C] : Cabecalho em formato HTML                             บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGenerico                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function MntHTMCb(cTituloM,cLinkLOGO,lEmpresa,lQuebra)

	Local cCabec			:= ""

	PARAMTYPE 0	VAR cTituloM	AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 1	VAR cLinkLOGO	AS Character	OPTIONAL	DEFAULT GetMV("MV_XLOGURL",.F.,"")
	PARAMTYPE 2	VAR lEmpresa	AS Logical		OPTIONAL	DEFAULT .T.
	PARAMTYPE 3	VAR lQuebra		AS Logical		OPTIONAL	DEFAULT .T.

	cCabec := '<html><head>' + CRLF
	cCabec += '<title>' + Upper(cTituloM) + '</title>' + CRLF
	cCabec += '<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">' + CRLF
	cCabec += '<style type="text/css">' + CRLF
	cCabec += 'body,td,th {font-family: Arial, Helvetica, sans-serif}' + CRLF
	cCabec += '</style>' + CRLF
	cCabec += '</head>' + CRLF
	//FORM
	cCabec += '<form name="FORM">' + CRLF
	cCabec += '<div align="center">' + CRLF
	cCabec += '<table background="" border="0" cellpadding="0" cellspacing="0" width="100%">' + CRLF
	cCabec += '<tbody>' + CRLF
	cCabec += '<tr>' + CRLF
	cCabec += '<td height="84">' + CRLF
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณCABECALHO PRINCIPAL  ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	cCabec += '<table border="0" cellpadding="0" cellspacing="0" width="100%">' + CRLF
	cCabec += '<tbody>' + CRLF
	cCabec += '<tr>' + CRLF
	cCabec += '<td height="16" width="33%">' + CRLF
	cCabec += '<div align="left">' + IIf(!Empty(cLinkLOGO),'<img src="' + RTrim(cLinkLOGO) + '" height="65" width="170">','') + '</div>' + CRLF
	cCabec += '</td>' + CRLF
	cCabec += '<td height="16" width="33%">' + CRLF
	cCabec += '<div align="center"><font face="Arial, Helvetica, sans-serif" size="2"><b><font size="4">' + cTituloM + '</font></b></font></div>' + CRLF
	cCabec += '</td>' + CRLF
	cCabec += '<td height="16" valign="top" width="34%"> <br>' + CRLF
	cCabec += '</td>' + CRLF
	cCabec += '</tr>' + CRLF
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณDADOS DA EMPRESA  ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	If lEmpresa
		cCabec += '<tr>' + CRLF
		cCabec += '<td colspan="2" height="41"><b><font face="Arial, Helvetica, sans-serif" size="1">' + SM0->M0_NOMECOM + '<br></font></b>' + CRLF
		cCabec += '<font face="Arial, Helvetica, sans-serif" size="1">' + "CNPJ : " + SM0->M0_CGC + '<br>' + CRLF
		cCabec += SM0->M0_ENDENT + '<br>' + CRLF
		cCabec += "CEP: " + RTrim(SM0->M0_CEPENT) + "- Tel. " + RTrim(SM0->M0_TEL) + '<br>' + CRLF
		cCabec += '</font></td>' + CRLF
		cCabec += '<td height="41" valign="top" width="34%"> <br>' + CRLF
		cCabec += '</td>' + CRLF
		cCabec += '</tr>' + CRLF
	Endif
	cCabec += '</tbody>' + CRLF
	cCabec += '</table>' + CRLF
	//QUEBRA DE LINHA
	If lQuebra
		cCabec += '<tr>' + CRLF
		cCabec += '<td>' + CRLF
		cCabec += '<hr noshade="noshade">' + CRLF
		cCabec += '</td>' + CRLF
		cCabec += '</tr>' + CRLF
	Endif

Return cCabec

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณMntHTMIt   บAutor  ณPablo Gollan Carreras บ Data ณ25/05/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณMonta cabecalho e conteudo de uma lista de itens                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[A] : Lista de campos, com a seguinte estrutura :            บฑฑ
ฑฑบ          ณ           [1] Nome do campo                                      บฑฑ
ฑฑบ          ณ           [2] Tamanho do campo                                   บฑฑ
ฑฑบ          ณ           [3] Titulo                                             บฑฑ
ฑฑบ          ณ           [4] Picture de formatacao de dados                     บฑฑ
ฑฑบ          ณExp02[A] : Array com a lista de valores                           บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณcMens[C] : Bloco de itens em formato HTML                         บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGenerico                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function MntHTMIt(aLstC,aLstVal,cTitulo,cRodape,lQuebra)

	Local cMens				:= ""
	Local nEspTotH			:= 0
	Local ni				:= 0
	Local nx				:= 0
	//Local nz				:= 0
	Local cMasc				:= ""

	PARAMTYPE 0	VAR aLstC		AS Array
	PARAMTYPE 1	VAR aLstVal		AS Array
	PARAMTYPE 2	VAR cTitulo		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 3	VAR cRodape		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 4	VAR lQuebra		AS Logical		OPTIONAL	DEFAULT .F.

	If Len(aLstC) # Len(aLstVal[1])
		Return cMens
	Endif
	If !Empty(cTitulo)
		cMens += '<table style="width: 100%;" nowrap="1" background="" border="0" bordercolor="#cccccc" cellpadding="0" cellspacing="0">' + CRLF
		cMens += '<tr><td>' + CRLF
		cMens += '<font face="Arial, Helvetica, sans-serif" size="4"><b>' + cTitulo + '</b></font>' + CRLF
		cMens += '</td></tr>'
		cMens += '</table>'
	Endif
	cMens += '<table style="width: 100%;" nowrap="1" background="" border="0" bordercolor="#cccccc" cellpadding="0" cellspacing="0">' + CRLF
	cMens += '<thead> <tr bgcolor="#cccccc">' + CRLF
	//Levantar o espacamento total das colunas
	nEspTotH := 0
	aEval(aLstC,{|x| nEspTotH += x[POS_HT_TAM]})
	For ni := 1 to Len(aLstC)
		cMens += '<td height="' + cValToChar(Int((aLstC[ni][POS_HT_TAM] / nEspTotH) * 100)) + '">' + CRLF
		cMens += '<div align="left"><b><font face="Arial, Helvetica, sans-serif" size="1">' + Capital(AllTrim(aLstC[ni][POS_HT_TIT])) + '</font></b></div>' + CRLF
		cMens += '</td>' + CRLF
	Next ni
	//ฺฤฤฤฤฤฤฤฟ
	//ณITENS  ณ
	//ภฤฤฤฤฤฤฤู
	cMens += '<tbody>' + CRLF
	For nx := 1 to Len(aLstVal)
		cMens += '<tr>' + CRLF
		For ni := 1 to Len(aLstC)
			cCmpAt := aLstC[ni][POS_HT_CMP]
			If Empty(cMasc := aLstC[ni][POS_HT_PIC])
				If Empty(cMasc := GetSX3Cache(cCmpAt,"X3_PICTURE"))
					cMasc := "@!"
				Endif
			Endif
			cMens += '<td>&nbsp;<font face="Verdana" size="1">' + Transform(aLstVal[nx][ni],cMasc) + '</font></td>' + CRLF
		Next ni
		cMens += '</tr>' + CRLF
	Next nx
	cMens += '</tbody>' + CRLF
	cMens += '</table>'
	//ฺฤฤฤฤฤฤฤฤฟ
	//ณQUEBRA  ณ
	//ภฤฤฤฤฤฤฤฤู
	If lQuebra
		cMens += '<tr>' + CRLF
		cMens += '<td>' + CRLF
		cMens += '<hr noshade="noshade">' + CRLF
		cMens += '</td>' + CRLF
		cMens += '</tr>' + CRLF
	Endif
	//ฺฤฤฤฤฤฤฤฤฟ
	//ณRODAPE  ณ
	//ภฤฤฤฤฤฤฤฤู
	If !Empty(cRodape)
		If !lQuebra
			cMens += "<p>" + CRLF
		Endif
		cMens += '<table style="width: 100%;" nowrap="1" background="" border="0" bordercolor="#cccccc" cellpadding="0" cellspacing="0">' + CRLF
		cMens += '<tr><td>' + CRLF
		cMens += '<font face="Arial, Helvetica, sans-serif" size="1">' + cRodape + '</font><p>' + CRLF
		cMens += '</td></tr>'
		cMens += '</table>'
	Endif

Return cMens

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณMntHTMRd   บAutor  ณPablo Gollan Carreras บ Data ณ25/05/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณMonta o rodape do arquivo HTML, deve trabalhar c/ os outros comp. บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณ                                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณcRodape[C] : Cabecalho em formato HTML                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGenerico                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function MntHTMRd()

	Local cRodape 			:= ""

	cRodape := '</tbody>' + CRLF
	cRodape += '</tbody>' + CRLF
	cRodape += '</table>' + CRLF
	cRodape += '</div>' + CRLF
	cRodape += '</form>' + CRLF
	cRodape += '</body></html>' + CRLF

Return cRodape

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณMntHTMMsg  บAutor  ณPablo Gollan Carreras บ Data ณ27/12/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณMonta um cabecalho de um arquivo HTML                             บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[C] : Titulo                                                 บฑฑ
ฑฑบ          ณExp02[C] : Link do logo da empresa ou o desejado                  บฑฑ
ฑฑบ          ณExp03[L] : Imprimir dados da empresa                              บฑฑ
ฑฑบ          ณExp04[C] : Mensagem do corpo do arquivo                           บฑฑ
ฑฑบ          ณExp05[A] : Array com as listas de registros a imprimir            บฑฑ
ฑฑบ          ณ           Estrutura por elemento :                               บฑฑ
ฑฑบ          ณ           [1] Lista de campos (cabecalho)                        บฑฑ
ฑฑบ          ณ           [2] Lista de valores                                   บฑฑ
ฑฑบ          ณ           [3] Titulo da lista                                    บฑฑ
ฑฑบ          ณ           [4] Impressao para rodape                              บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณcCabec[C] : Cabecalho em formato HTML                             บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGenerico                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function MntHTMMsg(cTitulo,cLinkLOGO,lInfoEmp,cMens,aLstREG)

	Local cHTML				:= ""
	Local ni				:= 0

	PARAMTYPE 0	VAR cTitulo		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 1	VAR cLinkLOGO	AS Character	OPTIONAL	DEFAULT GetMV("MV_XLOGURL",.F.,"")
	PARAMTYPE 2	VAR lInfoEmp	AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 3	VAR cMens		AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 4	VAR aLstREG		AS Array		OPTIONAL	DEFAULT Array(0)

	//Montar cabecalho
	cHTML := U_MntHTMCb(cTitulo,cLinkLOGO,lInfoEmp,.T.)
	//Montar bloco de mensagem
	If !Empty(cMens)
		cMens := StrTran(cMens,CHR(10),"")
		For ni := 1 to Len(cMens)
			//Formatar quebra de linha
			If Asc(Substr(cMens,ni,1)) == 13
				If ni < Len(cMens) .AND. Asc(Substr(cMens,ni + 1,1)) == 13
					cHTML += "<p>"
					ni++
				Else
					cHTML += "<br>"
				Endif
				Loop
			Endif
			cHTML += Substr(cMens,ni,1)
		Next ni
	Endif
	//Imprimir listas de registros
	For ni := 1 to Len(aLstREG)
		If ValType(aLstREG[ni]) # "A" .OR. Len(aLstREG[ni]) # 4 .OR. ValType(aLstREG[ni][1]) # "A" .OR. ValType(aLstREG[ni][2]) # "A"
			Loop
		Endif
		cHTML += U_MntHTMIt(aLstREG[ni][1],aLstREG[ni][2],aLstREG[ni][3],aLstREG[ni][4],.T.)
	Next ni
	//Rodape do arquivo
	cHTML += U_MntHTMRd()

Return cHTML

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณExBasPdG   บAutor  ณPablo Gollan Carreras บ Data ณ27/12/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณRotina que retorna se existe base de garantia pendente            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[C] : Codigo da filial                                       บฑฑ
ฑฑบ          ณExp02[C] : Codigo do fabricante                                   บฑฑ
ฑฑบ          ณExp03[C] : Loja do fabricante                                     บฑฑ
ฑฑบ          ณExp04[C] : Codigo do produto                                      บฑฑ
ฑฑบ          ณExp05[C] : Numero de serie                                        บฑฑ
ฑฑบ          ณExp06[C] : Lista de situacoes de garantia a considerar            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExp01[L] : Retorna se existe ou nao pendendia                     บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณSTR Ar Condicionado                                               บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function ExBasPdG(cFilPos,cCdFab,cLjFab,cCdPrd,cNumSer,aLstCdGar)

	Local lRet				:= .F.
	Local cAliasT			:= GetNextAlias()
	Local cRest01			:= ""
	Local ni				:= 0

	PARAMTYPE 0	VAR cFilPos		AS Character	OPTIONAL	DEFAULT xFilial("ABD")
	PARAMTYPE 1	VAR cCdFab		AS Character	OPTIONAL	DEFAULT Space(TamSX3("ABD_CODFAB")[1])
	PARAMTYPE 2	VAR cLjFab		AS Character	OPTIONAL	DEFAULT Space(TamSX3("ABD_LOJAFA")[1])
	PARAMTYPE 3	VAR cCdPrd		AS Character	OPTIONAL	DEFAULT Space(TamSX3("ABD_CODPRO")[1])
	PARAMTYPE 4	VAR cNumSer		AS Character	OPTIONAL	DEFAULT Space(TamSX3("ABD_NUMSER")[1])
	PARAMTYPE 5	VAR aLstCdGar	AS Array		OPTIONAL	DEFAULT Array(0)

	If !Empty(aLstCdGar)
		cRest01 := "ABD.ABD_XSITGA NOT IN ("
		aEval(aLstCdGar,{|x| ++ni,cRest01 += "'" + AllTrim(x) + "'" + IIf(ni < Len(aLstCdGar),",",")")})
	Else
		cRest01 := "ABD.ABD_XSITGA NOT IN ('00','99')"
	Endif
	cRest01 := "%" + cRest01 + "%"

	BeginSQL Alias cAliasT
		SELECT 1

		FROM %table:ABD% ABD

		WHERE ABD.%notDel%
		AND %exp:cRest01%
		AND ABD.ABD_FILIAL = %exp:cFilPos%
		AND ABD.ABD_CODFAB = %exp:cCdFab%
		AND ABD.ABD_LOJAFA = %exp:cLjFab%
		AND ABD.ABD_CODPRO = %exp:cCdPrd%
		AND ABD.ABD_NUMSER = %exp:cNumSer%
		AND ABD.ABD_STATUS = '1'
		AND ABD.ABD_DATABX = %exp:Space(TamSX3("ABD_DATABX")[1])%
	EndSQL
	(cAliasT)->(dbGoTop())
	lRet := !(cAliasT)->(Eof())
	U_FecArTMP(cAliasT)

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณMT103AtNS  บAutor  ณPablo Gollan Carreras บ Data ณ27/12/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณRotina para atualizar o numero de serie em notas de devolucao     บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณ                                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExp01[C] : Retorna numero de serie encontrado                     บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณSTR Ar Condicionado                                               บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function MT103AtNS()

	Local cRet				:= ""
	Local bOk				:= {|| ExecBlock("RtFunName",.F.,.F.) == "MATA103" .AND. INCLUI .AND. Type("CTIPO") == "C" .AND. ;
	M->CTIPO == "D" .AND. !Empty(GDFieldPos("D1_XNSEROR",aHeader))}
	Local aArea				:= SaveArea1({"SZA"})
	Local aLstC01			:= {"D1_COD","D1_NFORI","D1_SERIORI","D1_ITEMORI"}
	Local aPosCp			:= Array(Len(aLstC01))
	Local ni				:= 0
	Local uValAt			:= ""
	Local cAlvo				:= ""

	If !Eval(bOk)
		Return Nil
	Endif
	cRet := CriaVar("D1_XNSEROR",.F.)
	aFill(aPosCp,0)
	aEval(aLstC01,{|x| ++ni,aPosCp[ni] := GDFieldPos(x,aHeader)})
	//Montar a expressao de pesquisa
	For ni := 1 to Len(aLstC01)
		//Caso o campo nao possua referencia de posicao, interromper a montagem da expressao
		If Empty(aPosCp[ni])
			Exit
		Endif
		//Verificar se o campo atual esta posicionado
		If !Empty(uValAt := IIf(aLstC01[ni] $ ReadVar(),&(ReadVar()),aCols[n][aPosCp[ni]]))
			cAlvo += uValAt
		Else
			//Caso o campo esteja vazio, interromper a montagem da expressao
			Exit
		Endif
	Next ni
	//Caso exista expressao, efetuar a pequisa
	If !Empty(cAlvo)
		cAlvo := xFilial("SZA") + cAlvo
		dbSelectArea("SZA")
		SZA->(dbSetOrder(3))	//ZA_FILIAL+ZA_COD+ZA_DOC+ZA_SERIE+ZA_ITEM
		SZA->(dbSeek(cAlvo))
		If SZA->(Found())
			cRet := SZA->ZA_NUMSER
		Endif
	Endif
	RestArea1(aArea)

Return cRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณRtLgStBs   บAutor  ณPablo Gollan Carreras บ Data ณ03/01/13        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณRotina para retornar o codigo de cor da situacao da base instaladaบฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณ                                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExp01[C] : Retorna codigo de cor                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณSTR Ar Condicionado                                               บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function RtLgStBs()

	Local cRet			:= "BR_BRANCO"

	If Empty(Select("AA3")) .OR. AA3->(Bof()) .OR. AA3->(Eof())
		Return cRet
	Endif
	Do Case
		Case AA3->AA3_STATUS == "01"	//Em cliente
		cRet := "BR_VERDE"
		Case AA3->AA3_STATUS == "02"	//Em estoque
		cRet := "BR_LARANJA"
		Case AA3->AA3_STATUS == "03"	//Em manutencao
		cRet := "BR_VERMELHO"
		Case AA3->AA3_STATUS == "04"	//Em nosso poder
		cRet := "BR_CINZA"
	EndCase

Return cRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณLstCpBrw   บAutor  ณPablo Gollan Carreras บ Data ณ31/07/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณRotina para retornar a lista de campos a serem listados no browse บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[C] : Alias da tabela                                        บฑฑ
ฑฑบ          ณExp02[N] : Tipo de retorno 1=String 2=Array                       บฑฑ
ฑฑบ          ณExp03[L] : Incluir o campo filial para retorno                    บฑฑ
ฑฑบ          ณExp04[N] : Formatao da array de retorno de dados                  บฑฑ
ฑฑบ          ณExp05[A] : Lista de campos a pesquisar (FIXO)                     บฑฑ
ฑฑบ          ณExp06[A] : Lista de campos para nao listar                        บฑฑ
ฑฑบ          ณExp07[B] : Bloco de codigo para decisao da utilizacao de campos   บฑฑ
ฑฑบ          ณExp08[B] : Remover espacos do titulo                              บฑฑ
ฑฑบ          ณExp09[B] : Remover espacos do nome do campo                       บฑฑ
ฑฑบ          ณExp10[L] : Listar campos que nao sejam marcados como browse       บฑฑ
ฑฑบ          ณExp11[A] : Campos adicionais que nao estao marcados como browse   บฑฑ
ฑฑบ          ณ           no SX3 e que devem ser listados.                       บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExp01[U] : Retorno com lista de campos como string ou array       บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGENERICO                                                          บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ001        บAutor  ณPablo Gollan Carreras บ Data ณ16/08/2012      บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ1.Inclusao de novas estruturas de retorno                         บฑฑ
ฑฑบ          ณ2.Inclusao da opcao de pesquisa de lista fixa de campos           บฑฑ
ฑฑบ          ณ3.Inclusao da opcao de lista de campos para nao listar no retorno บฑฑ
ฑฑบ          ณ4.Inclusao de tomada de decisao auxiliar para emprego de campos   บฑฑ
ฑฑบ          ณ5.Controle de remocao de espacos de campos e titulos para retorno บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ002        บAutor  ณPablo Gollan Carreras	บ Data ณ20/08/2012      บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ1.Tratamento para nao considerar campo browse na validacao de     บฑฑ
ฑฑบ          ณ  utilizacao de campos.                                           บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ003        บAutor  ณPablo Gollan Carreras บ Data ณ10/01/2012      บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณInclusao de parametro p/ inclusao de campos nao listados na browseบฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function LstCpBrw(cAlias,nTpRet,lIncFil,nArrFrm,aLstC,aLstCNL,bDecisaoAux,lRmEspT,lRmEspC,lLCpNBr,aLstCAd)

	Local uRet				:= ""
	Local aAreaSX3			:= SX3->(GetArea())
	Local ni				:= 0
	Local nx				:= 0
	Local cCpAt				:= ""
	Local aEstRtArr			:= {}
	Local aTMP				:= {}
	Local bForma			:= {|x| Upper(AllTrim(x))}
	Local nMetodo			:= 1
	Local bCpOk				:= {|| (X3Uso(SX3->X3_USADO) .AND. (lLCpNBr .OR. SX3->X3_BROWSE # "N") .AND. cNivel >= SX3->X3_NIVEL .AND. ;
	Empty(aScan(aLstCNL,{|x| Eval(bForma,x) == Eval(bForma,SX3->X3_CAMPO)})) .AND. Eval(bDecisaoAux)) .OR. ;
	IIf(lIncFil,"_FILIAL" $ SX3->X3_CAMPO,.F.)}

	Private bFormaRT		:= {|x| IIf(lRmEspT,AllTrim(x),x)}
	Private bFormaRC		:= {|x| IIf(lRmEspC,AllTrim(x),x)}

	PARAMTYPE 0		VAR cAlias			AS Character	OPTIONAL	DEFAULT ""
	PARAMTYPE 1		VAR nTpRet			AS Numeric		OPTIONAL	DEFAULT 1
	PARAMTYPE 2		VAR lIncFil			AS Logical		OPTIONAL 	DEFAULT .F.
	PARAMTYPE 3		VAR nArrFrm			AS Numeric		OPTIONAL	DEFAULT 1
	PARAMTYPE 4		VAR aLstC			AS Array		OPTIONAL	DEFAULT Array(0)
	PARAMTYPE 5		VAR aLstCNL			AS Array		OPTIONAL	DEFAULT Array(0)
	PARAMTYPE 6		VAR bDecisaoAux		AS Block		OPTIONAL	DEFAULT {|| AllwaysTrue()}
	PARAMTYPE 7		VAR lRmEspT			AS Logical		OPTIONAL	DEFAULT .T.
	PARAMTYPE 8		VAR lRmEspC			AS Logical		OPTIONAL	DEFAULT .F.
	PARAMTYPE 9		VAR lLCpNBr			AS Logical		OPTIONAL	DEFAULT .T.
	PARAMTYPE 10	VAR aLstCAd			AS Array		OPTIONAL	DEFAULT Array(0)

	uRet := IIf(nTpRet == 1,"",Array(0))
	If Empty(cAlias) .OR. !cValToChar(nTpRet) $ "1|2"
		Return uRet
	Endif
	If !Empty(aLstCAd)
		aLstC := aClone(aLstCAd)
		nMetodo := 3
	Else
		If !Empty(aLstC)
			nMetodo := 2
		Endif
	Endif
	//Definir os campos para o formato do retorno
	If nTpRet == 2
		Do Case
			Case nArrFrm == 1
			aEstRtArr := {	"Eval(bFormaRT,X3Descric())",;
			"Eval(bFormaRC,SX3->X3_CAMPO)"}

			//Estrutura para TCBrowse
			Case nArrFrm == 2
			aEstRtArr := {	"Eval(bFormaRT,X3Descric())",;
			"Eval(bFormaRC,SX3->X3_CAMPO)",;
			"SX3->X3_TIPO",;
			"SX3->X3_TAMANHO",;
			"SX3->X3_DECIMAL",;
			"SX3->X3_PICTURE"}

			Case nArrFrm == 3
			aEstRtArr := {	"Eval(bFormaRC,SX3->X3_CAMPO)"}

			//Estrutura para MsNewGetDados
			Case nArrFrm == 4
			aEstRtArr := {	"Eval(bFormaRT,X3Titulo())",;
			"Eval(bFormaRC,SX3->X3_CAMPO)",;
			"SX3->X3_PICTURE",;
			"SX3->X3_TAMANHO",;
			"SX3->X3_DECIMAL",;
			"SX3->X3_VALID",;
			"SX3->X3_USADO",;
			"SX3->X3_TIPO",;
			"SX3->X3_F3",;
			"SX3->X3_CONTEXT",;
			"SX3->X3_CBOX",;
			"SX3->X3_RELACAO",;
			"SX3->X3_WHEN",;
			"SX3->X3_VISUAL",;
			"SX3->X3_VLDUSER",;
			"SX3->X3_PICTVAR",;
			"SX3->X3_OBRIGAT"}

			Case nArrFrm == 5
			aEstRtArr := {	"Eval(bFormaRT,X3Titulo())",;
			"Eval(bFormaRC,SX3->X3_CAMPO)",;
			"SX3->X3_PICTURE",;
			"SX3->X3_TAMANHO",;
			"SX3->X3_DECIMAL",;
			"SX3->X3_VALID",;
			"SX3->X3_USADO",;
			"SX3->X3_TIPO",;
			"SX3->X3_F3",;
			"SX3->X3_CONTEXT"}
		EndCase
	Endif
	dbSelectArea("SX3")
	If cValToChar(nMetodo) $ "1|3"
		SX3->(dbSetOrder(1))
		SX3->(dbSeek(cAlias))
		Do While !SX3->(Eof()) .AND. Eval(bForma,SX3->X3_ARQUIVO) == Eval(bForma,cAlias)
			If Eval(bCpOk)
				cCpAt := Eval(bFormaRC,SX3->X3_CAMPO)
				Do Case
					Case nTpRet == 1
					uRet += cCpAt + ","
					Otherwise
					aTMP := {}
					For ni := 1 to Len(aEstRtArr)
						aAdd(aTMP,&(aEstRtArr[ni]))
					Next ni
					aAdd(uRet,aClone(aTMP))
				EndCase
			Endif
			SX3->(dbSkip())
		EndDo
	Endif
	If cValToChar(nMetodo) $ "2|3"
		SX3->(dbSetOrder(2))
		For ni := 1 to Len(aLstC)
			If SX3->(dbSeek(PadR(aLstC[ni],10)))
				If Eval(bCpOk) .OR. !Empty(aScan(aLstCAd,{|x| AllTrim(x) == AllTrim(SX3->X3_CAMPO)}))
					cCpAt := Eval(bFormaRC,SX3->X3_CAMPO)
					Do Case
						Case nTpRet == 1
						uRet += cCpAt + ","
						Otherwise
						aTMP := {}
						For nx := 1 to Len(aEstRtArr)
							aAdd(aTMP,&(aEstRtArr[nx]))
						Next nx
						aAdd(uRet,aClone(aTMP))
					EndCase
				Endif
			Endif
		Next ni
	Endif
	If !Empty(uRet) .AND. nTpRet == 1
		uRet := Substr(uRet,1,Len(uRet) - 1)
	Endif
	RestArea(aAreaSX3)

Return uRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออออหออออออัอออออออออออออออออปฑฑ
ฑฑบPrograma  ณApRedFWL  บAutor  ณPablo Gollan Carreras บ Data ณ03/02/2012       บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออออสออออออฯอออออออออออออออออนฑฑ
ฑฑบDesc.     ณDefine se deve ser aplicado reducao de tamanho para a classe      บฑฑ
ฑฑบ          ณFWLayer nas janelas, em interface MDI e/ou com tema TEMAP10.      บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[A] : Considerar a versao do FWLayer                         บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGenerico                                                          บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function ApRedFWL(lConsVer)

	Local lRet				:= .F.
	Local bCond				:= {|| }

	PARAMTYPE 0	VAR lConsVer	AS Logical	OPTIONAL	DEFAULT .F.

	If !lConsVer
		bCond := &('{|| (AllTrim(PtGetTheme()) == "MDI" .OR. AllTrim(GetTheme()) == "TEMAP10")}')
	Else
		bCond := &('{|| (AllTrim(PtGetTheme()) == "MDI" .OR. AllTrim(GetTheme()) == "TEMAP10") .AND. AllTrim(GetVersao(.F.)) # "11" .AND. ' + ;
		'CtoD(DtoC(GetAPOInfo("FWLAYER.PRW")[4])) < CtoD("1/1/2011")}')
	Endif
	If Eval(bCond)
		lRet := .T.
	Endif

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณIsDevGar   บAutor  ณPablo Gollan Carreras บ Data ณ08/01/13        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณDefine se o codigo de devolucao eh de garantia                    บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณNenhum                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณSTR Ar Condicionado                                               บฑฑ
ฑฑฬออออออออออุอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออนฑฑ
ฑฑบRevisao   ณ           บAutor  ณ                      บ Data ณ                บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDescricao ณ                                                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function IsDevGar(cCodDev)

	Local lRet				:= .F.
	Local aLstCdGar			:= IIf(!Empty(SuperGetMV("MV_XMTDEVG",.F.,"")),StrTokArr(SuperGetMV("MV_XMTDEVG",.F.,""),","),Array(0))
	Local cCodDevEB			:= PARAMIXB

	PARAMTYPE 0	VAR cCodDev		AS CHARACTER	OPTIONAL	DEFAULT cCodDevEB

	If !Empty(cCodDev) .AND. !Empty(aScan(aLstCdGar,{|x| AllTrim(x) == AllTrim(cCodDev)}))
		lRet := !lRet
	Endif

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออออหออออออัออออออออออออออออปฑฑ
ฑฑบPrograma  ณDefTamObj  บAutor  ณPablo Gollan Carreras บ Data ณ09/02/12        บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออออสออออออฯออออออออออออออออนฑฑ
ฑฑบDesc.     ณFuncao para alimentar variavel de definicao de tamanho e posicio- บฑฑ
ฑฑบ          ณnamento de objeto.                                                บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExp01[A] : Array de tamanho e posicionamento                      บฑฑ
ฑฑบ          ณExp02[N] : TOP                                                    บฑฑ
ฑฑบ          ณExp03[N] : LEFT                                                   บฑฑ
ฑฑบ          ณExp04[N] : WIDTH                                                  บฑฑ
ฑฑบ          ณExp05[N] : HEIGHT                                                 บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณ                                                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณGenerico                                                          บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function DefTamObj(aTamObj,nTOP,nLEFT,nWIDTH,nBOTTOM,lAcVlZr)

	PARAMTYPE 0	VAR aTamObj		AS Array		OPTIONAL	DEFAULT Array(4)
	PARAMTYPE 1	VAR nTOP		AS Numeric		OPTIONAL	DEFAULT 0
	PARAMTYPE 2	VAR nLEFT		AS Numeric		OPTIONAL	DEFAULT 0
	PARAMTYPE 3	VAR nWIDTH		AS Numeric		OPTIONAL	DEFAULT 0
	PARAMTYPE 4	VAR nBOTTOM		AS Numeric		OPTIONAL	DEFAULT 0
	PARAMTYPE 5	VAR	lAcVlZr		AS Logical		OPTIONAL	DEFAULT .F.

	If Len(aTamObj) # 4
		aTamObj := Array(4)
	Endif
	If lAcVlZr .OR. (!lAcVlZr .AND. !Empty(nTOP))
		aTamObj[1] := nTOP
	Endif
	If lAcVlZr .OR. (!lAcVlZr .AND. !Empty(nLEFT))
		aTamObj[2] := nLEFT
	Endif
	If lAcVlZr .OR. (!lAcVlZr .AND. !Empty(nWIDTH))
		aTamObj[3] := nWIDTH
	Endif
	If lAcVlZr .OR. (!lAcVlZr .AND. !Empty(nBOTTOM))
		aTamObj[4] := nBOTTOM
	Endif

Return Nil

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑฺฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฟฑฑ
ฑฑณFun…o    ณPutSx1 ESPECIFICO ACEEX   ณ Autor ณMarcos Santos            ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณDescri…o ณCria uma pergunta usando rotina padrao                      ณฑฑ
ฑฑณtivemos que criar esta funcao especifica pois na v12 foi desabilitada  ณฑฑ
ฑฑภฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤูฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
User Function PutSx1PG(cGrupo,cOrdem,cPergunt,cPerSpa,cPerEng,cVar,;
	cTipo ,nTamanho,nDecimal,nPresel,cGSC,cValid,;
	cF3, cGrpSxg,cPyme,;
	cVar01,cDef01,cDefSpa1,cDefEng1,cCnt01,;
	cDef02,cDefSpa2,cDefEng2,;
	cDef03,cDefSpa3,cDefEng3,;
	cDef04,cDefSpa4,cDefEng4,;
	cDef05,cDefSpa5,cDefEng5,;
	aHelpPor,aHelpEng,aHelpSpa,cHelp)

	LOCAL aArea := GetArea()
	Local cKey
	Local lPort := .f.
	Local lSpa  := .f.
	Local lIngl := .f.

	cKey  := "P." + AllTrim( cGrupo ) + AllTrim( cOrdem ) + "."

	cPyme    := Iif( cPyme 		== Nil, " ", cPyme		)
	cF3      := Iif( cF3 		== NIl, " ", cF3		)
	cGrpSxg  := Iif( cGrpSxg	== Nil, " ", cGrpSxg	)
	cCnt01   := Iif( cCnt01		== Nil, "" , cCnt01 	)
	cHelp	 := Iif( cHelp		== Nil, "" , cHelp		)

	dbSelectArea( "SX1" )
	dbSetOrder( 1 )

	// Ajusta o tamanho do grupo. Ajuste emergencial para valida็ใo dos fontes.
	// RFC - 15/03/2007
	cGrupo := PadR( cGrupo , Len( SX1->X1_GRUPO ) , " " )

	If !( DbSeek( cGrupo + cOrdem ))

		cPergunt:= If(! "?" $ cPergunt .And. ! Empty(cPergunt),Alltrim(cPergunt)+" ?",cPergunt)
		cPerSpa	:= If(! "?" $ cPerSpa  .And. ! Empty(cPerSpa) ,Alltrim(cPerSpa) +" ?",cPerSpa)
		cPerEng	:= If(! "?" $ cPerEng  .And. ! Empty(cPerEng) ,Alltrim(cPerEng) +" ?",cPerEng)

		Reclock( "SX1" , .T. )

		Replace X1_GRUPO   With cGrupo
		Replace X1_ORDEM   With cOrdem
		Replace X1_PERGUNT With cPergunt
		Replace X1_PERSPA  With cPerSpa
		Replace X1_PERENG  With cPerEng
		Replace X1_VARIAVL With cVar
		Replace X1_TIPO    With cTipo
		Replace X1_TAMANHO With nTamanho
		Replace X1_DECIMAL With nDecimal
		Replace X1_PRESEL  With nPresel
		Replace X1_GSC     With cGSC
		Replace X1_VALID   With cValid

		Replace X1_VAR01   With cVar01

		Replace X1_F3      With cF3
		Replace X1_GRPSXG  With cGrpSxg

		If Fieldpos("X1_PYME") > 0
			If cPyme != Nil
				Replace X1_PYME With cPyme
			Endif
		Endif

		Replace X1_CNT01   With cCnt01
		If cGSC == "C"			// Mult Escolha
			Replace X1_DEF01   With cDef01
			Replace X1_DEFSPA1 With cDefSpa1
			Replace X1_DEFENG1 With cDefEng1

			Replace X1_DEF02   With cDef02
			Replace X1_DEFSPA2 With cDefSpa2
			Replace X1_DEFENG2 With cDefEng2

			Replace X1_DEF03   With cDef03
			Replace X1_DEFSPA3 With cDefSpa3
			Replace X1_DEFENG3 With cDefEng3

			Replace X1_DEF04   With cDef04
			Replace X1_DEFSPA4 With cDefSpa4
			Replace X1_DEFENG4 With cDefEng4

			Replace X1_DEF05   With cDef05
			Replace X1_DEFSPA5 With cDefSpa5
			Replace X1_DEFENG5 With cDefEng5
		Endif

		Replace X1_HELP  With cHelp

		SX1HelpPG(cKey,aHelpPor,aHelpEng,aHelpSpa)

		MsUnlock()
	Else

		lPort := ! "?" $ X1_PERGUNT .And. ! Empty(SX1->X1_PERGUNT)
		lSpa  := ! "?" $ X1_PERSPA  .And. ! Empty(SX1->X1_PERSPA)
		lIngl := ! "?" $ X1_PERENG  .And. ! Empty(SX1->X1_PERENG)

		If lPort .Or. lSpa .Or. lIngl
			RecLock("SX1",.F.)
			If lPort
				SX1->X1_PERGUNT:= Alltrim(SX1->X1_PERGUNT)+" ?"
			EndIf
			If lSpa
				SX1->X1_PERSPA := Alltrim(SX1->X1_PERSPA) +" ?"
			EndIf
			If lIngl
				SX1->X1_PERENG := Alltrim(SX1->X1_PERENG) +" ?"
			EndIf
			SX1->(MsUnLock())
		EndIf
	Endif

	RestArea( aArea )

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑฺฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฟฑฑ
ฑฑณFun…o    ณSX1Help ESPECIFICO ACEEX   ณ Autor ณ                        ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณDescri…o ณCria um Help usando rotina padrao                           ณฑฑ
ฑฑภฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤูฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function SX1HelpPG(cKey,aHelpPor,aHelpEng,aHelpSpa,lUpdate,cStatus)
	Local cFilePor := "SIGAHLP.HLP"
	Local cFileEng := "SIGAHLE.HLE"
	Local cFileSpa := "SIGAHLS.HLS"
	Local nRet
	Local nT
	Local nI
	Local cLast
	Local cNewMemo
	Local cAlterPath := ''
	Local nPos

	If ( ExistBlock('HLPALTERPATH') )
		cAlterPath := Upper(AllTrim(ExecBlock('HLPALTERPATH', .F., .F.)))
		If ( ValType(cAlterPath) != 'C' )
			cAlterPath := ''
		ElseIf ( (nPos:=Rat('\', cAlterPath)) == 1 )
			cAlterPath += '\'
		ElseIf ( nPos == 0	)
			cAlterPath := '\' + cAlterPath + '\'
		EndIf

		cFilePor := cAlterPath + cFilePor
		cFileEng := cAlterPath + cFileEng
		cFileSpa := cAlterPath + cFileSpa

	EndIf

	Default aHelpPor := {}
	Default aHelpEng := {}
	Default aHelpSpa := {}
	Default lUpdate  := .T.
	Default cStatus  := ""

	If Empty(cKey)
		Return
	EndIf

	If !(cStatus $ "USER|MODIFIED|TEMPLATE")
		cStatus := NIL
	EndIf

	cLast 	 := ""
	cNewMemo := ""

	nT := Len(aHelpPor)

	For nI:= 1 to nT
		cLast := Padr(aHelpPor[nI],40)
		If nI == nT
			cLast := RTrim(cLast)
		EndIf
		cNewMemo+= cLast
	Next

	If !Empty(cNewMemo)
		nRet := SPF_SEEK( cFilePor, cKey, 1 )
		If nRet < 0
			SPF_INSERT( cFilePor, cKey, cStatus,, cNewMemo )
		Else
			If lUpdate
				SPF_UPDATE( cFilePor, nRet, cKey, cStatus,, cNewMemo )
			EndIf
		EndIf
	EndIf

	cLast 	 := ""
	cNewMemo := ""

	nT := Len(aHelpEng)

	For nI:= 1 to nT
		cLast := Padr(aHelpEng[nI],40)
		If nI == nT
			cLast := RTrim(cLast)
		EndIf
		cNewMemo+= cLast
	Next

	If !Empty(cNewMemo)
		nRet := SPF_SEEK( cFileEng, cKey, 1 )
		If nRet < 0
			SPF_INSERT( cFileEng, cKey, cStatus,, cNewMemo )
		Else
			If lUpdate
				SPF_UPDATE( cFileEng, nRet, cKey, cStatus,, cNewMemo )
			EndIf
		EndIf
	EndIf

	cLast 	 := ""
	cNewMemo := ""

	nT := Len(aHelpSpa)

	For nI:= 1 to nT
		cLast := Padr(aHelpSpa[nI],40)
		If nI == nT
			cLast := RTrim(cLast)
		EndIf
		cNewMemo+= cLast
	Next

	If !Empty(cNewMemo)
		nRet := SPF_SEEK( cFileSpa, cKey, 1 )
		If nRet < 0
			SPF_INSERT( cFileSpa, cKey, cStatus,, cNewMemo )
		Else
			If lUpdate
				SPF_UPDATE( cFileSpa, nRet, cKey, cStatus,, cNewMemo )
			EndIf
		EndIf
	EndIf
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑฺฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฟฑฑ
ฑฑณFun…o    ณXValidPG ESPECIFICO ACEEX   ณ Autor ณ                     ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤดฑฑ
Cria uma pergunta usando rotina padrao                                    ณฑฑ
ฑฑณtivemos que criar esta funcao especifica pois na v12 foi desabilitada  ณฑฑ
ฑฑภฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤูฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
User Function XValidPG(aRegs,cPerg,lAltera,aCpoComp)
	//-- Transferimos o Conteudo do Array para variaveis
	//-- Alguns Elementos (Cnt02..Cnt05,...) estao mantindos para compatibilizacao
	//-- Embora nao sejam utilizados
	Local cGrupo	:=cPerg
	Local cOrdem	,cPergunt	,cPerSpa	,cPerEng	, cVar		,cTipo
	Local nTamanho	,nDecimal	,nPresel	,cGSC		, cValid	,cF3
	Local cGrpSxg	,cVar01	    ,cDef01		,cDefSpa1	, cDefEng1	,cCnt01
	Local cVar02	,cDef02		,cDefSpa2	,cDefEng2	, cCnt02	,cVar03
	Local cDef03	,cDefSpa3	,cDefEng3	,cCnt03		, cVar04	, cDef04
	Local cDefSpa4	,cDefEng4	,cCnt04		,cVar05		, cDef05	, cDefSpa5
	Local cDefEng5	,cCnt05		,cPyme		,aHelpPor	,aHelpEng	,aHelpSpa
	Local cHelp
	Local nX, nY, cCpoComp, nPosComp
	Local nTamX1GRUPO	:= Len(SX1->X1_GRUPO)

	Local nSX1Order:=0
	Local lCriarNovo:=lIncluiAltera:=.F.

	Local nLenaRegs

	DEFAULT aCpoComp := {}

	nSX1Order := SX1->(IndexOrd())
	SX1->(dbSetOrder(1))
	cPerg := Left(cPerg+Spac(nTamX1GRUPO), nTamX1GRUPO)
	cGrupo:=cPerg
	//-- Corre Todas as Perguntas
	For nX:=1 to Len(aRegs)
		//-- Obtem o tamanho do array da pergunta lida para posterior comparacao
		nLenaRegs:=Len(aRegs[nX])
		//-- Carrega os Elementos do Array para Variaveis afim de facilitar a leitura
		//-- do fonte
		cOrdem	:= aRegs[nX,02]
		cPergunt:= aRegs[nX,03];cPerSpa		:= aRegs[nX,04]
		cPerEng	:= aRegs[nX,05];cVar		:= aRegs[nX,06]; cTipo		:= aRegs[nX,07]
		nTamanho:= aRegs[nX,08];nDecimal	:= aRegs[nX,09]; nPresel	:= aRegs[nX,10]
		cGSC	:= aRegs[nX,11];cValid		:= aRegs[nX,12]
		cVar01	:= aRegs[nX,13]

		cCnt01	:= If(17 > nLenaRegs,"",aRegs[nX,17])

		If cGSC == "C"			// Mult Escolha
			cDef01	:= If(14 > nLenaRegs,"",aRegs[nX,14])
			cDefSpa1:= If(15 > nLenaRegs,"",aRegs[nX,15])
			cDefEng1:= If(16 > nLenaRegs,"",aRegs[nX,16])

			cVar02	:= If(18 > nLenaRegs,"",aRegs[nX,18])
			cDef02	:= If(19 > nLenaRegs,"",aRegs[nX,19])
			cDefSpa2:= If(20 > nLenaRegs,"",aRegs[nX,20])
			cDefEng2:= If(21 > nLenaRegs,"",aRegs[nX,21])
			cCnt02	:= If(22 > nLenaRegs,"",aRegs[nX,22])

			cVar03	:= If(23 > nLenaRegs,"",aRegs[nX,23])
			cDef03	:= If(24 > nLenaRegs,"",aRegs[nX,24])
			cDefSpa3:= If(25 > nLenaRegs,"",aRegs[nX,25])
			cDefEng3:= If(26 > nLenaRegs,"",aRegs[nX,26])
			cCnt03	:= If(27 > nLenaRegs,"",aRegs[nX,27])

			cVar04	:= If(28 > nLenaRegs,"",aRegs[nX,28])
			cDef04	:= If(29 > nLenaRegs,"",aRegs[nX,29])
			cDefSpa4:= If(30 > nLenaRegs,"",aRegs[nX,30])
			cDefEng4:= If(31 > nLenaRegs,"",aRegs[nX,31])
			cCnt04	:= If(32 > nLenaRegs,"",aRegs[nX,32])

			cVar05	:= If(33 > nLenaRegs,"",aRegs[nX,33])
			cDef05	:= If(34 > nLenaRegs,"",aRegs[nX,34])
			cDefSpa5:= If(35 > nLenaRegs,"",aRegs[nX,35])
			cDefEng5:= If(36 > nLenaRegs,"",aRegs[nX,36])
			cCnt05	:= If(37 > nLenaRegs,"",aRegs[nX,37])

		Endif

		//-- Trata Campos Especiais que podem nao ser fornecidos
		cF3		:= If(38 > nLenaRegs,"",aRegs[nX,38])
		cGrpSxg	:= If(39 > nLenaRegs,"",aRegs[nX,39])
		cPyme	:= If(40 > nLenaRegs,"",aRegs[nX,40])
		aHelpPor:= If(41 > nLenaRegs,{},aRegs[nX,41])
		aHelpEng:= If(42 > nLenaRegs,{},aRegs[nX,42])
		aHelpSpa:= If(43 > nLenaRegs,{},aRegs[nX,43])
		cHelp   := If(44 > nLenaRegs,"",aRegs[nX,44])

		lIncluiAltera:=.F.
		lCriarNovo:=.F.

		//-- Procura pelo Grupo de Perguntas e Item
		If SX1->(dbSeek(cPerg+aRegs[nX,2]))

			//-- Se Houver Divergencia nos Textos das Perguntas em qualquer Idioma
			//-- Forca a OPERACAO: regravacao das informacoes
			lIncluiAltera := (  (SX1->X1_PERGUNT # aRegs[nX,3])    .OR. ;
			(!Empty(aRegs[nX,4])  .AND. SX1->X1_PERSPA  # aRegs[nX,4])    .OR. ;
			(!Empty(aRegs[nX,5])  .AND. SX1->X1_PERENG  # aRegs[nX,5]) ;
			)
			If !lIncluiAltera
				If ValType( aCpoComp ) == "A" .And. Len( aCpoComp ) > 0
					For nY := 1 To Len( aCpoComp )
						If ( nPosComp := SX1->(FieldPos( aCpoComp[nY] )) ) > 0 .And. nPosComp <= nLenaRegs
							cCpoComp := If(">" $ aCpoComp[nY], aCpoComp[nY], "SX1->"+aCpoComp[nY] )
							If ( lIncluiAltera := &( cCpoComp ) <> aRegs[nX,nPosComp] )
								Exit
							EndIf
						EndIf
					Next nY
				EndIf
			EndIf

			//-- OPERACAO: ALTERAR registro
			lCriarNovo:=.F. //-- Nao Cria Novo Registro

		Else
			//-- Se for uma nova pergunta forca a OPERACAO: inclusao das informacoes
			lIncluiAltera:=.T.
			//-- OPERACAO: INCLUIR novo registro
			lCriarNovo:=.T.
		Endif

		//--Se deve realizar a OPERACAO:
		If lIncluiAltera
			//-- Para Alteracao Eliminamos a Pergunta Atual
			If !lCriarNovo
				FDelSX1(cGrupo,cPergunt,SX1->X1_Ordem,SX1->X1_Ordem,.T.)
			Endif
			//-- Inclui Nova Pegunta
			u_PutSx1PG(cGrupo,cOrdem	,cPergunt	,cPerSpa	,cPerEng	,cVar	,;
			cTipo 	,nTamanho	,nDecimal	,nPresel	,cGSC	,cValid,;
			cF3		, cGrpSxg	,cPyme		,;
			cVar01	,cDef01		,cDefSpa1	,cDefEng1	,cCnt01	,;
			cDef02	,cDefSpa2	,cDefEng2	,;
			cDef03	,cDefSpa3	,cDefEng3	,;
			cDef04	,cDefSpa4	,cDefEng4	,;
			cDef05	,cDefSpa5	,cDefEng5	,;
			aHelpPor	,aHelpEng	,aHelpSpa	,cHelp )

		Endif
	Next nX

	SX1->(dbSetOrder(nSX1Order))

Return
