defineClass("ViewController", {
	  jsSel:function (){
		  	var alertView = require('UIAlertView')
			      .alloc()
				        .initWithTitle_message_delegate_cancelButtonTitle_otherButtonTitles(
						        "Alert",
								        "ss", 
										        self, 
												        "OK", 
														        null
																      )
						     alertView.show()
		  },
})
