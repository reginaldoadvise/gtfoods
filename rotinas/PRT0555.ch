#IFDEF SPANISH

	//-----------------------------------------------------------------------------------------------
	// PRT0555 - Programa para Relatório de Fatura por email
	//-----------------------------------------------------------------------------------------------
	#DEFINE CAT555001 "¡Factura enviada al cliente con éxito!"
	#DEFINE CAT555002 "Estimado cliente, sigue adjunto su factura."
	#DEFINE CAT555003 "¡E-mail creado con éxito!"
	#DEFINE CAT555004 "Facturación por FT "
	#DEFINE CAT555005 "Cliente sin E-mail registrado."
	#DEFINE CAT555006 "Cliente sin E-mail registrado."

#ELSE
	#IFDEF ENGLISH

		//-----------------------------------------------------------------------------------------------
		// PRT0555 - Programa para Relatório de Fatura por email
		//-----------------------------------------------------------------------------------------------
		#DEFINE CAT555001 "Invoice report send successfully to the customer!"
		#DEFINE CAT555002 "Dear customer, your invoice is attached."
		#DEFINE CAT555003 "E-mail created successfully!"
		#DEFINE CAT555004 "Billing for Invoice "
		#DEFINE CAT555005 "Customer without registered email."

	#ELSE

		//-----------------------------------------------------------------------------------------------
		// PRT0555 - Programa para Relatório de Fatura por email
		//-----------------------------------------------------------------------------------------------
		#DEFINE CAT555001 "Fatura enviada com sucesso ao cliente!"
		#DEFINE CAT555002 "Prezado(a) cliente, segue em anexo sua fatura."
		#DEFINE CAT555003 "E-mail criado com sucesso!"
		#DEFINE CAT555004 "Faturamento referente a FT "
		#DEFINE CAT555005 "Cliente sem e-mail cadastrado."

	#ENDIF
#ENDIF
