defineClass("ViewController", {
	  jsSel:function (){
		   self.localSel();
		  },
})


defineClass("TestObject", {
	  test:function (){
		  	var alertView = require('UIAlertView')
			      .allc()
				        .initWithTitle_message_delegate_cancelButtonTitle_otherButtonTitles(
						        "Alert",
								        "test", 
										        self, 
												        "OK", 
														        null
																      )
						     alertView.show()
		  },
})
