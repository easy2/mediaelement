stop();
import htmlElements.SwfElementAS2;

MovieClip.prototype.getChildByName = function(mcName):MovieClip {
	return this[mcName];
}

	var _mediaUrl:String = "";
	 var _autoplay:Boolean;
	 var _preload:String;
	 var _debug:Boolean;
	 var _isVideo:Boolean;
	 var _isSwf:Boolean;

	 var _timerRate:Number;
	 var _stageWidth:Number;
	 var _stageHeight:Number;
	 var _enableSmoothing:Boolean;
	 var _allowedPluginDomain:String;
	 var _isFullScreen:Boolean = false;
	 var _startVolume:Number;
	 var _controlStyle:String;
	 var _autoHide:Boolean = true;

	// native video size (from meta data)
	 var _nativeVideoWidth:Number = 0;
	 var _nativeVideoHeight:Number = 0;

	// visual elements
	 var _output:TextField;
	 var _fullscreenButton:MovieClip;

	// media
	 var _mediaElement:Object; //----------------------   SwfElementAS2;

	// CONTROLS
	 var _alwaysShowControls:Boolean;
	 var _controlBar:MovieClip;
	 var _controlBarBg:MovieClip;
	 var _scrubBar:MovieClip;
	 var _scrubTrack:MovieClip;
	 var _scrubOverlay:MovieClip;
	 var _scrubLoaded:MovieClip;
	 var _hoverTime:MovieClip;
	 var _hoverTimeText:TextField;
	 var _playButton:MovieClip;
	 var _pauseButton:MovieClip;
	 var _duration:TextField;
	 var _currentTime:TextField;
	 var _fullscreenIcon:MovieClip;
	 var _volumeMuted:MovieClip;
	 var _volumeUnMuted:MovieClip;
	 var _scrubTrackColor:String;
	 var _scrubBarColor:String;
	 var _scrubLoadedColor:String;

	
	
	// IDLE Timer for mouse for showing/hiding controls
	 var _inactiveTime:Number;
	 var _autoHideTimeout:Number;
	 var _idleTime:Number;
	 var _isMouseActive:Boolean
	 var _isOverStage:Boolean = false;


	 function initFlashMediaElement():Void {

		// show allow this player to be called from a different domain than the HTML page hosting the player
		Security.allowDomain("*");

		// get parameters
		var params:Object = _root;
		_mediaUrl = (params['file'] != undefined) ? String(params['file']) : "";
		_isSwf = (getExtenstion(_mediaUrl) == "swf");
		_autoplay = (params['autoplay'] != undefined) ? (String(params['autoplay']) == "true") : false;
		_debug = (params['debug'] != undefined) ? (String(params['debug']) == "true") : false;
		_isVideo = (params['isvideo'] != undefined) ? ((String(params['isvideo']) == "false") ? false : true  ) : true;
		_timerRate = (params['timerrate'] != undefined) ? (parseInt(params['timerrate'], 10)) : 250;
		_alwaysShowControls = (params['controls'] != undefined) ? (String(params['controls']) == "true") : false;
		_enableSmoothing = (params['smoothing'] != undefined) ? (String(params['smoothing']) == "true") : false;
		_startVolume = (params['startvolume'] != undefined) ? (parseFloat(params['startvolume'])) : 0.8;
		_preload = (params['preload'] != undefined) ? params['preload'] : "none";
		_controlStyle = (params['controlstyle'] != undefined) ? (String(params['controlstyle'])) : ""; // blank or "floating"
		_autoHide = (params['autohide'] != undefined) ? (String(params['autohide'])) : true;
		_scrubTrackColor = (params['scrubtrackcolor'] != undefined) ? (String(params['scrubtrackcolor'])) : "0x333333";
		_scrubBarColor = (params['scrubbarcolor'] != undefined) ? (String(params['scrubbarcolor'])) : "0xefefef";
		_scrubLoadedColor = (params['scrubloadedcolor'] != undefined) ? (String(params['scrubloadedcolor'])) : "0x3CACC8";

		
		if (isNaN(_timerRate))
			_timerRate = 250;

		// setup stage and player sizes/scales
		Stage.align = "TL";
		Stage.scaleMode = "noScale";
		_stageWidth = Stage._width;
		_stageHeight = Stage._height;

		//_autoplay = true;
		//_mediaUrl  = "http://mediafiles.dts.edu/chapel/mp4/20100609.mp4";
		//_alwaysShowControls = true;
		//_mediaUrl  = "../media/Parades-PastLives.mp3";
		//_mediaUrl  = "../media/echo-hereweare.mp4";

		//_mediaUrl = "http://video.ted.com/talks/podcast/AlGore_2006_480.mp4";
		//_mediaUrl = "rtmp://stream2.france24._yacast.net/france24_live/en/f24_liveen";

		

		// position and hide
		_fullscreenButton = getChildByName("fullscreen_btn");
		//_fullscreenButton._visible = false;
		_fullscreenButton._alpha = 0;
		_fullscreenButton.addEventListener(MouseEvent.CLICK, fullscreenClick, false);
		_fullscreenButton._x = stage.stageWidth - _fullscreenButton._width;
		_fullscreenButton._y = stage.stageHeight - _fullscreenButton._height;
		
		// create media element
		if(_isSwf) {
			_mediaElement = new SwfElement(this, _autoplay, _preload, _timerRate, _startVolume);
			addChild(_mediaElement);
		} 

		// controls!
		_controlBar = getChildByName("controls_mc");
		_controlBarBg = _controlBar.getChildByName("controls_bg_mc");
		_scrubTrack = _controlBar.getChildByName("scrubTrack");
		_scrubBar = _controlBar.getChildByName("scrubBar");
		_scrubOverlay = _controlBar.getChildByName("scrubOverlay");
		_scrubLoaded = _controlBar.getChildByName("scrubLoaded");
		
		_scrubOverlay.buttonMode = true;
		_scrubOverlay.useHandCursor = true
		
		applyColor(_scrubTrack, _scrubTrackColor);
		applyColor(_scrubBar, _scrubBarColor);
		applyColor(_scrubLoaded, _scrubLoadedColor);
		
		_fullscreenIcon = _controlBar.getChildByName("fullscreenIcon");
		
		// New fullscreenIcon for new fullscreen floating controls
		//if(_alwaysShowControls && _controlStyle.toUpperCase()=="FLOATING") {
			_fullscreenIcon.addEventListener(MouseEvent.CLICK, fullScreenIconClick, false);
		//}
		
		_volumeMuted = _controlBar.getChildByName("muted_mc");
		_volumeUnMuted = _controlBar.getChildByName("unmuted_mc");
		
		_volumeMuted.addEventListener(MouseEvent.CLICK, toggleVolume, false);
		_volumeUnMuted.addEventListener(MouseEvent.CLICK, toggleVolume, false);
		
		_playButton = _controlBar.getChildByName("play_btn");
		_playButton.onPress = function() {
			_mediaElement.play();					 
		};
		_pauseButton = _controlBar.getChildByName("pause_btn");
		_pauseButton.onPress = function() {
			_mediaElement.pause();					 
		};
		_pauseButton._visible = false;
		_duration = _controlBar.getChildByName("duration_txt");
		_currentTime = _controlBar.getChildByName("currentTime_txt");
		_hoverTime = _controlBar.getChildByName("hoverTime");
		_hoverTimeText = _hoverTime.getChildByName("hoverTime_txt");
		_hoverTime._visible=false;
		_hoverTime._y=(_hoverTime._height/2)+1;
		_hoverTime._x=0;
		

		
		// Add new timeline scrubber events
		_scrubOverlay.addEventListener(MouseEvent.MOUSE_MOVE, scrubMove);
		_scrubOverlay.addEventListener(MouseEvent.CLICK, scrubClick);
		_scrubOverlay.addEventListener(MouseEvent.MOUSE_OVER, scrubOver);
		_scrubOverlay.addEventListener(MouseEvent.MOUSE_OUT, scrubOut);
		
		if (_autoHide) { // && _alwaysShowControls) {
			// Add mouse activity for show/hide of controls
			stage.addEventListener(Event.MOUSE_LEAVE, mouseActivityLeave);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseActivityMove);
			_inactiveTime = 2500;
			_autoHideTimer = setTimeout(function():Void {
					idleTimer();
			}, _timerRate)
			// set
		}
		
		if(_alwaysShowControls) {
			if(_startVolume<=0) {
				_volumeMuted._visible=true;
				_volumeUnMuted._visible=false;
			} else {
				_volumeMuted._visible=false;
				_volumeUnMuted._visible=true;
			}
		}

		_controlBar._visible = _alwaysShowControls;
		addChild(_controlBar);

		// put back on top
		addChild(_fullscreenButton);
		//_fullscreenButton._alpha = 0;
		//_fullscreenButton._visible = true;

		if (_mediaUrl != "") {
			_mediaElement.setSrc(_mediaUrl);
		}

		positionControls();
		
		// Fire this once just to set the width on some dynamically sized scrub bar items;
		_scrubBar.scaleX=0;
		_scrubLoaded.scaleX=0;
		
		setUpExternalInterfaceCallbacks();

		if (_preload != "none") {
			_mediaElement.load();
			
			if (_autoplay) {
				_mediaElement.play();
			}
		} else if (_autoplay) {
			_mediaElement.load();
			_mediaElement.play();
		}


		stage.addEventListener(Event.RESIZE, resizeHandler);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, stageClicked);
		stage.addEventListener(FullScreenEvent.FULL_SCREEN, stageFullScreenChanged);	
	}
	function setUpExternalInterfaceCallbacks():Void {
		if (ExternalInterface.available) { //  && !_alwaysShowControls

			try {
				if (ExternalInterface.objectID != null && ExternalInterface.objectID.toString() != "") {
					
					// add HTML media methods
					ExternalInterface.addCallback("playMedia", playMedia);
					ExternalInterface.addCallback("loadMedia", loadMedia);
					ExternalInterface.addCallback("pauseMedia", pauseMedia);
					ExternalInterface.addCallback("stopMedia", stopMedia);

					ExternalInterface.addCallback("setSrc", setSrc);
					ExternalInterface.addCallback("setCurrentTime", setCurrentTime);
					ExternalInterface.addCallback("setVolume", setVolume);
					ExternalInterface.addCallback("setMuted", setMuted);

					ExternalInterface.addCallback("setFullscreen", setFullscreen);
					ExternalInterface.addCallback("setVideoSize", setVideoSize);
					
					ExternalInterface.addCallback("positionFullscreenButton", positionFullscreenButton);
					ExternalInterface.addCallback("hideFullscreenButton", hideFullscreenButton);

					// fire init method					
					ExternalInterface.call("mejs.MediaPluginBridge.initPlugin", ExternalInterface.objectID);
				}

			}  catch (error:Error) {
				
			}

		}
	}
			
	// START: Controls and events
	function mouseActivityMove():Void {
		
		// if mouse is in the video area
		if (_autoHide && (_root._xmouse >=0 && _root._xmouse <= Stage.stageWidth) && (_root._ymouse>=0 && _root._ymouse <= Stage.stageHeight)) {

			// This could be move to a nice fade at some point...
			_controlBar._visible = (_alwaysShowControls || _isFullScreen);
			_isMouseActive = true;
			_idleTime = 0;
			clearTimeout(_autoHideTimer);
			_autoHideTimer = setTimeout(function():Void {
				 ideltimer();
			});
		}
	}
	
	function mouseActivityLeave():Void {
		if (_autoHide) {
			_isOverStage = false;
			// This could be move to a nice fade at some point...
			_controlBar._visible = false;
			_isMouseActive = false;
			_idleTime = 0;
			clearTimeout(_autoHideTimer);
			_autoHideTimer = setTimeout(function():Void {
				 ideltimer();
			});
		}
	}
	
	function idleTimer():Void    {
	  
		if (_autoHide) {
			// This could be move to a nice fade at some point...
			_controlBar._visible = false;
			_isMouseActive = false;
			_idleTime += _inactiveTime;
			_idleTime = 0;
			clearTimeout(_autoHideTimer);
			_autoHideTimer = setTimeout(function():Void {
				 ideltimer();
			});
		} 
	}
	
	
	function scrubMove():Void {
		var event:Object = {}; //TODO - ADD Mouse handlers correctly
		if (_hoverTime._visible) {
			var seekBarPosition:Number =  ((event.localX / _scrubTrack._width) *_mediaElement.duration())*_scrubTrack.scaleX;
			var hoverPos:Number = (seekBarPosition / _mediaElement.duration()) *_scrubTrack.scaleX;
			
			if (_isFullScreen) {
				_hoverTime._x=event.target.parent.mouseX;
			} else {
				_hoverTime._x=mouseX;
			}
			_hoverTime._y = _scrubBar._y - (_hoverTime._height/2);
			_hoverTimeText.text = secondsToTimeCode(seekBarPosition);
		}
	}
	
	function scrubOver():Void {
		_hoverTime._y = _scrubBar._y-(_hoverTime._height/2)+1;
		_hoverTime._visible = true;
	}
	
	function scrubOut():Void {
		_hoverTime._y = _scrubBar._y+(_hoverTime._height/2)+1;
		_hoverTime._visible = false;
	}
	
	function scrubClick():Void {
		var event:Object = {}; //TODO - ADD Mouse handlers correctly
		var seekBarPosition:Number =  ((event.localX / _scrubTrack._width) *_mediaElement.duration())*_scrubTrack.scaleX;

		var tmp:Number = (_mediaElement.currentTime()/_mediaElement.duration())*_scrubTrack._width;
		var canSeekToPosition:Boolean = _scrubLoaded.scaleX > (seekBarPosition / _mediaElement.duration()) *_scrubTrack.scaleX;
		
		if (seekBarPosition>0 && seekBarPosition<_mediaElement.duration() && canSeekToPosition) {
				_mediaElement.setCurrentTime(seekBarPosition);
		}
	}
	
	function toggleVolume():Void {
		var event:Object = { currentTarget:{name:""}}; //TODO - ADD Mouse handlers correctly
		switch(event.currentTarget.name) {
			case "muted_mc":
				setMuted(false);
				break;
			case "unmuted_mc":
				setMuted(true);
				break;
		}
	}
	
	function toggleVolumeIcons(volume:Number) {
		if(volume<=0) {
			_volumeMuted._visible = true;
			_volumeUnMuted._visible = false;
		} else {
			_volumeMuted._visible = false;
			_volumeUnMuted._visible = true;
		}
	}
	
	function positionControls(forced:Boolean=false) {
		
		
		if ( _controlStyle.toUpperCase() == "FLOATING" && _isFullScreen) {

			_hoverTime._y=(_hoverTime._height/2)+1;
			_hoverTime._x=0;
			_controlBarBg._width = 300;
			_controlBarBg._height = 93;
			//_controlBarBg._x = (stage.stageWidth/2) - (_controlBarBg._width/2);
			//_controlBarBg._y  = stage.stageHeight - 300;
			
			_pauseButton.scaleX = _playButton.scaleX=3.5;
			_pauseButton.scaleY= _playButton.scaleY=3.5;
			// center the play button and make it big and at the top
			_pauseButton._x = _playButton._x = (_controlBarBg._width/2)-(_playButton._width/2)+7;
			_pauseButton._y = _playButton._y = _controlBarBg._height-_playButton._height-(14)
							
			_controlBar._x = (stage.stageWidth/2) -150;
			_controlBar._y = stage.stageHeight - _controlBar._height-100;
			
			
			// reposition the time and duration items
			
			_duration._x = _controlBarBg._width - _duration._width - 10;
			_duration._y = _controlBarBg._height - _duration._height -7;
			//_currentTime._x = _controlBarBg._width - _duration._width - 10 - _currentTime._width - 10;
			_currentTime._x = 5
			_currentTime._y= _controlBarBg._height - _currentTime._height-7;
			
			_fullscreenIcon._x = _controlBarBg._width - _fullscreenIcon._width - 7;
			_fullscreenIcon._y = 7;
			
			_volumeMuted._x = _volumeUnMuted._x = 7;
			_volumeMuted._y = _volumeUnMuted._y = 7;
			
			_scrubLoaded._x = _scrubBar._x = _scrubOverlay._x = _scrubTrack._x =_currentTime._x+_currentTime._width+7;
			_scrubLoaded._y = _scrubBar._y = _scrubOverlay._y = _scrubTrack._y=_controlBarBg._height-_scrubTrack._height-10;
			
			_scrubBar._width =  _scrubOverlay._width = _scrubTrack._width = (_duration._x-_duration._width-14);

			
		} else {

			_hoverTime._y=(_hoverTime._height/2)+1;
			_hoverTime._x=0;
			_controlBarBg._width = stage.stageWidth;
			_controlBarBg._height = 30;
			_controlBarBg._y=0;
			_controlBarBg._x=0;
			// _controlBarBg._x = 0;
			// _controlBarBg._y  = stage.stageHeight - _controlBar._height;
			
			_pauseButton.scaleX = _playButton.scaleX=1;
			_pauseButton.scaleY = _playButton.scaleY=1;
			
			_pauseButton._x = _playButton._x = 7;
			_pauseButton._y = _playButton._y = _controlBarBg._height-_playButton._height-2;
			
			
			//_currentTime._x = stage.stageWidth - _duration._width - 10 - _currentTime._width - 10;
			_currentTime._x = _playButton._x+_playButton._width;
			
			_fullscreenIcon._x = _controlBarBg._width - _fullscreenIcon._width - 7;
			_fullscreenIcon._y = 8;
			
			_volumeMuted._x = _volumeUnMuted._x = _fullscreenIcon._x - _volumeMuted._width - 10;
			_volumeMuted._y = _volumeUnMuted._y = 10;
			
			_duration._x = _volumeMuted._x - _volumeMuted._width - _duration._width + 5;
			_duration._y = _currentTime._y = _controlBarBg._height - _currentTime._height - 7;
			
			_scrubLoaded._x = _scrubBar._x = _scrubOverlay._x = _scrubTrack._x = _currentTime._x + _currentTime._width + 10;
			_scrubLoaded._y = _scrubBar._y = _scrubOverlay._y = _scrubTrack._y = _controlBarBg._height - _scrubTrack._height - 9;
			
			_scrubBar._width =  _scrubOverlay._width = _scrubTrack._width =  (_duration._x-_duration._width-10)-_duration._width+5;
			_controlBar._x = 0;
			_controlBar._y = stage.stageHeight - _controlBar._height;
			
		}
		
	}
	
	// END: Controls
	

	function stageClicked(e:MouseEvent):Void {
		//_output.appendText("click: " + e.stageX.toString() +","+e.stageY.toString() + "\n");
		sendEvent("click", "");
	}

	function resizeHandler(e:Event):Void {
		//_video.scaleX = stage.stageWidth / _stageWidth;
		//_video.scaleY = stage.stageHeight / _stageHeight;
		//positionControls();
		
		repositionVideo();
	}

	// START: Fullscreen		
	function enterFullscreen() {
		var screenRectangle:Rectangle = new Rectangle(_video._x, _video._y, flash.system.Capabilities.screenResolutionX, flash.system.Capabilities.screenResolutionY); 
		stage.fullScreenSourceRect = screenRectangle;
		
		Stage.displayState = "fullScreen";
		
		repositionVideo(true);
		
		_controlBar._visible = true;
		
		_isFullScreen = true;
	}
	
	function exitFullscreen() {
	
		Stage.displayState = "normal";
			
		
		_controlBar._visible = false;
		
		_isFullScreen = false;	
	}

	function setFullscreen(gofullscreen:Boolean) {

		try {
			//_fullscreenButton._visible = false;

			if (gofullscreen) {
				enterFullscreen();

			} else {
				exitFullscreen();
			}

		} catch (error:Error) {

			// show the button when the security error doesn't let it work
			//_fullscreenButton._visible = true;
			_fullscreenButton._alpha = 1;

			_isFullScreen = false;   
		}
	}
	
	// control bar button/icon 
	function fullScreenIconClick(e:MouseEvent) {
		try {
			_controlBar._visible = true;
			setFullscreen(!_isFullScreen);
			repositionVideo(_isFullScreen);
		} catch (error:Error) {
		}
	}

	// special floating fullscreen icon
	function fullscreenClick(e:MouseEvent) {
		//_fullscreenButton._visible = false;
		_fullscreenButton._alpha = 0

		try {
			_controlBar._visible = true;
			setFullscreen(true);
			repositionVideo(true);
			positionControls();
		} catch (error:Error) {
		}
	}
	
	
	function stageFullScreenChanged(e:FullScreenEvent) {
		//_fullscreenButton._visible = false;
		_fullscreenButton._alpha = 0;
		_isFullScreen = e.fullScreen;
		
		sendEvent(HtmlMediaEvent.FULLSCREENCHANGE, "isFullScreen:" + e.fullScreen );

		if (!e.fullScreen) {
			_controlBar._visible = _alwaysShowControls;
		}
	}
	// END: Fullscreen

	// START: external interface 
	function playMedia() {
		_mediaElement.play();
	}
	function loadMedia() {
		_mediaElement.load();
	}
	function pauseMedia() {
		_mediaElement.pause();
	}
	function setSrc(url:String) {
		_mediaElement.setSrc(url);
	}
	function stopMedia() {
		_mediaElement.stop();
	}
	function setCurrentTime(time:Number) {
		_mediaElement.setCurrentTime(time);
	}
	function setVolume(volume:Number) {
		_mediaElement.setVolume(volume);
		toggleVolumeIcons(volume);
	}
	function setMuted(muted:Boolean) {
		_mediaElement.setMuted(muted);
		toggleVolumeIcons(_mediaElement.getVolume());
	}
	function setVideoSize(width:Number, height:Number) {
		_stageWidth = width;
		_stageHeight = height;

		if (_video != null) {
			repositionVideo();
			positionControls();
		}
	}
	function positionFullscreenButton(x:Number, y:Number, visibleAndAbove:Boolean ) {
		if (visibleAndAbove) {
			_fullscreenButton._x = x+1;
			_fullscreenButton._y = y - _fullscreenButton._height+1;	
		} else {
			_fullscreenButton._x = x;
			_fullscreenButton._y = y;	
		}
		
		// check for oversizing
		if ((_fullscreenButton._x + _fullscreenButton._width) > stage.stageWidth)
			_fullscreenButton._x = stage.stageWidth - _fullscreenButton._width;
		
		// show it!
		if (visibleAndAbove) {
			_fullscreenButton._alpha = 1;
		}
	}
	function hideFullscreenButton() {
		_fullscreenButton._alpha = 0;
	}		
	
	// END: external interface
	
	function repositionVideo(fullscreen:Boolean = false):Void {

		if (_nativeVideoWidth <= 0 || _nativeVideoHeight <= 0) {
			//_mediaElement.play();
			return;
		}

		// calculate ratios
		var stageRatio, nativeRatio;
		
		_video._x = 0;
		_video._y = 0;			
		
		if(fullscreen == true) {
			stageRatio = flash.system.Capabilities.screenResolutionX/flash.system.Capabilities.screenResolutionY;
			nativeRatio = _nativeVideoWidth/_nativeVideoHeight;

			// adjust size and position
			if (nativeRatio > stageRatio) {
				_video._width = flash.system.Capabilities.screenResolutionX;
				_video._height = _nativeVideoHeight * flash.system.Capabilities.screenResolutionX / _nativeVideoWidth;
				_video._y = flash.system.Capabilities.screenResolutionY/2 - _video._height/2;
			} else if (stageRatio > nativeRatio) {
				_video._height = flash.system.Capabilities.screenResolutionY;
				_video._width = _nativeVideoWidth * flash.system.Capabilities.screenResolutionY / _nativeVideoHeight;
				_video._x = flash.system.Capabilities.screenResolutionX/2 - _video._width/2;
			} else if (stageRatio == nativeRatio) {
				_video._height = flash.system.Capabilities.screenResolutionY;
				_video._width = flash.system.Capabilities.screenResolutionX;

			}
		} else {
			stageRatio = _stageWidth/_stageHeight;
			nativeRatio = _nativeVideoWidth/_nativeVideoHeight;

			// adjust size and position
			if (nativeRatio > stageRatio) {
				_video._width = _stageWidth;
				_video._height = _nativeVideoHeight * _stageWidth / _nativeVideoWidth;
				_video._y = _stageHeight/2 - _video._height/2;
			} else if (stageRatio > nativeRatio) {
				_video._height = _stageHeight;
				_video._width = _nativeVideoWidth * _stageHeight / _nativeVideoHeight;
				_video._x = _stageWidth/2 - _video._width/2;
			} else if (stageRatio == nativeRatio) {
				_video._height = _stageHeight;
				_video._width = _stageWidth;
			}
		}

		positionControls();
	}

	// SEND events to JavaScript
	function sendEvent(eventName:String, eventValues:String) {			

		// special video event
		if (eventName == HtmlMediaEvent.LOADEDMETADATA && _isVideo) {
			//trace("METADATA RECEIVED!");
			_nativeVideoWidth = (_mediaElement as VideoElement).videoWidth;
			_nativeVideoHeight = (_mediaElement as VideoElement).videoHeight;

			 if(stage.displayState == "fullScreen" ) {
				setVideoSize(_nativeVideoWidth, _nativeVideoHeight);
				repositionVideo(true);
			 } else {
				repositionVideo();
			 }
		}

		// update controls
		switch (eventName) {
			case "pause":
			case "paused":
			case "ended":
				_playButton._visible = true;
				_pauseButton._visible = false;
				break;
			case "play":
			case "playing":
				_playButton._visible = false;
				_pauseButton._visible = true;
				break;
		}
		//_duration.text = (_mediaElement.duration()*1).toString(); 
		_duration.text =  secondsToTimeCode(_mediaElement.duration());
		//_currentTime.text = (_mediaElement.currentTime()*1).toString(); 
		_currentTime.text =  secondsToTimeCode(_mediaElement.currentTime());

		var pct:Number =  (_mediaElement.currentTime() / _mediaElement.duration()) *_scrubTrack.scaleX;
		
		_scrubBar.scaleX = pct;
		_scrubLoaded.scaleX = (_mediaElement.currentProgress()*_scrubTrack.scaleX)/100;
		
		//trace((_mediaElement.duration()*1).toString() + " / " + (_mediaElement.currentTime()*1).toString());
		//trace("CurrentProgress:"+_mediaElement.currentProgress());
		
		if (ExternalInterface.objectID != null && ExternalInterface.objectID.toString() != "") {

			if (eventValues == null)
				eventValues == "";

			if (_isVideo) {
				eventValues += (eventValues != "" ? "," : "") + "isFullScreen:" + _isFullScreen;
			}

			eventValues = "{" + eventValues + "}";

			ExternalInterface.call("setTimeout", "mejs.MediaPluginBridge.fireEvent('" + ExternalInterface.objectID + "','" + eventName + "'," + eventValues + ")",0);
		}
	}
	 function getExtenstion(mediaUrl:String):String {
		if(!mediaUrl)
			return null;
		var parts:Array = mediaUrl.split(".");
		return parts[parts.length-1];
	}

	// START: utility
	function secondsToTimeCode(seconds:Number):String {
		var timeCode:String = "";
		seconds = Math.round(seconds);
		var minutes:Number = Math.floor(seconds / 60);
		timeCode = (minutes >= 10) ? minutes.toString() : "0" + minutes.toString();
		seconds = Math.floor(seconds % 60);
		timeCode += ":" + ((seconds >= 10) ? seconds.toString() : "0" + seconds.toString());
		return timeCode; //minutes.toString() + ":" + seconds.toString();
	}
	
	function applyColor(item:Object, color:String):Void {
		
		var myColor:ColorTransform = item.transform.colorTransform;
		myColor.color = Number(color);
		item.transform.colorTransform = myColor;
	}
	// END: utility 
	/*
	*/
		

