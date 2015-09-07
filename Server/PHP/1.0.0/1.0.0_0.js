defineClass("ViewController", {
	  jsSel:function (){
		  	var alertView = require('UIAlertView')
			      .alloc()
				        .initWithTitle_message_delegate_cancelButtonTitle_otherButtonTitles(
						        "Alert",
								        "1.0.0_0 Patch", 
										        self, 
												        "OK", 
														        null
																      )
						     alertView.show()
		  },
})
