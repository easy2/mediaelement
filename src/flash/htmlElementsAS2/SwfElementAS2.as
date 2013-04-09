import htmlElementsAS2.HtmlMediaEventAS2;
class htmlElementsAS2.SwfElementAS2{
		
		
		private var _sound:Sound;

		private var _volume:Number = 1;
		private var _preMuteVolume:Number = 0;
		private var _isMuted:Boolean = false;
		private var _isPaused:Boolean = true;
		private var _isEnded:Boolean = false;
		private var _isLoaded:Boolean = false;
		private var _currentTime:Number = 0;
		private var _duration:Number = 0;
		private var _bytesLoaded:Number = 0;
		private var _bytesTotal:Number = 0;

		private var _currentUrl:String = "";
		private var _autoplay:Boolean = true;
		private var _preload:String = "";

		private var _element:MovieClip;
		private var _firedCanPlay:Boolean = false;
		private var _playAfterLoading:Boolean= true;
		
		private var _swfContent:MovieClip;
		private var _swfCurrentFrame:Number = 0;
		private var _swfTotalFrames:Number = 0;
		private var _shouldCenter:Boolean = true;
		
		private var _frameRate:Number = 30;
		
		private var _holder:MovieClip;
		private var _loader:MovieClipLoader;
		private var _that:SwfElementAS2;
		
		public function duration():Number {
			return _duration;
		}

		public function currentTime():Number {
			return _currentTime;
		}
		
		public function currentProgress():Number {
				return Math.round(_bytesLoaded/_bytesTotal*100);
		}

		public function SwfElementAS2(element:MovieClip, autoplay:Boolean, preload:String, timerRate:Number, startVolume:Number, holder:MovieClip) 
		{
			_that = this;
			_element = element;
			_autoplay = autoplay;
			_volume = startVolume;
			_preload = preload;

			_sound = new Sound();
			setVolume(_volume);

			_holder = holder;
		}
		
		// MovieClipLoader callbacks 
		public function onLoadProgress (mc:MovieClip, loadedBytes:Number, totalBytes:Number):Void {
			_bytesLoaded = loadedBytes;
			_bytesTotal = totalBytes;
			sendEvent(HtmlMediaEventAS2.PROGRESS);
		}
		public function onLoadError ():Void {
			//do nothing, load has failed!
		}
		public function onLoadInit(mc:MovieClip):Void {			
			_isLoaded = true;

			_swfContent = mc;
			
			_swfTotalFrames = _swfContent._totalFrames; 
			_swfCurrentFrame = 0;
			if(_swfContent) {
				_duration =  _swfTotalFrames/_frameRate;
				
				sendEvent(HtmlMediaEventAS2.LOADEDDATA);
				sendEvent(HtmlMediaEventAS2.CANPLAY);
				_firedCanPlay = true;
				
				_holder.addEventListener("onEnterFrame", handleFrameEnter, this);
			} else {
				_that.onLoadError();
			}
		}
		// end MovieClipLoader Callbacks
		
		//events
		
		public function handleFrameEnter():Void {
			
			if(_isPaused && _playAfterLoading == true) {
				_that.play();
				_playAfterLoading = false;
				return;
			}
			
			if(!_isPaused) {
				_swfCurrentFrame = _swfContent._currentframe;
				_currentTime =_swfCurrentFrame / _frameRate;
				
				sendEvent(HtmlMediaEventAS2.TIMEUPDATE);
				
				if(_swfCurrentFrame >= _swfTotalFrames) {
					_currentTime = 0;
					_isEnded = true;
		
					sendEvent(HtmlMediaEventAS2.ENDED);
				}
			}
		}
		
		// METHODS
		public function setSrc(url:String):Void {
			_currentUrl = url;
			_isLoaded = false;
		}

		public function load():Void {
			if (_currentUrl == "")
				return;
		
			_currentTime = 0;
			_swfCurrentFrame = 0;
			
			_loader = new MovieClipLoader();
			_loader.checkPolicyFile = true;
			_loader.addListener(this);

			_swfContent = _holder.createEmptyMovieClip("loadedSwf", _holder.getNextHighestDepth());
			_loader.loadClip(_currentUrl, _swfContent);
			
			sendEvent(HtmlMediaEventAS2.LOADSTART);
		}

		public function play():Void {
			if (!_isLoaded) {
				return;
			}
				
			var frame:Number = Math.max(2, _swfCurrentFrame); //for some reason we start on frame 2
			_swfContent.gotoAndPlay(frame);

			didStartPlaying();
		}

		public function pause():Void {
			_swfContent.stop();
			_isPaused = true;
			sendEvent(HtmlMediaEventAS2.PAUSE);
		}

		public function stop():Void {
			_swfContent.stop();
			_isPaused = true;
			sendEvent(HtmlMediaEventAS2.STOP);
		}

		public function setCurrentTime(pos:Number):Void {
			_currentTime = pos;
			var frame:Number = Math.round(_frameRate * _currentTime);
			frame = Math.max(Math.min(frame, _swfTotalFrames), 2);

			_swfContent.gotoAndPlay(frame);
			
			didStartPlaying();
		}
		
		private function didStartPlaying():Void {
			_isPaused = false;
			sendEvent(HtmlMediaEventAS2.PLAY);
			sendEvent(HtmlMediaEventAS2.PLAYING);
			
			if (!_firedCanPlay) {
				sendEvent(HtmlMediaEventAS2.LOADEDDATA);
				sendEvent(HtmlMediaEventAS2.CANPLAY);				
				_firedCanPlay = true;
			}
		}
		
		public function setVolume(volume:Number):Void {
			_volume = volume;

			_sound.setVolume(_volume * 100);
			_isMuted = (_volume == 0);
			
			sendEvent(HtmlMediaEventAS2.VOLUMECHANGE);
		}
		
		public function getVolume():Number {
			if(_isMuted) {
				return 0;
			} else {
				return _volume;
			}
		}

		public function setMuted(muted:Boolean):Void {

			// ignore if already set
			if ( (muted && _isMuted) || (!muted && !_isMuted))
				return;

			if (muted) {
				_preMuteVolume = _sound.getVolume()/100;
				setVolume(0);
			} else {
				setVolume(_preMuteVolume);
			}

			_isMuted = muted;
		}
		public function resize(w:Number, h:Number):Void {
			if(_swfContent != null) {
				//_swfContent._x = Math.max(0, (w - _holder._width)/2);
				//_swfContent._y = Math.max(0, (h - _holder._height)/2);
			}
		}

		private function sendEvent(eventName:String) {

			// calculate this to mimic HTML5
			var bufferedTime:Number = _bytesLoaded / _bytesTotal * _duration;

			// build JSON
			var values:String = "duration:" + _duration + 
							",currentTime:" + _currentTime + 
							",muted:" + _isMuted + 
							",paused:" + _isPaused + 
							",ended:" + _isEnded + 
							",volume:" + _volume +
							",src:\"" + _currentUrl + "\"" +
							",bytesTotal:" + _bytesTotal +
							",bufferedBytes:" + _bytesLoaded +
							",bufferedTime:" + bufferedTime +
							"";

			_element.sendEvent(eventName, values);
		}
		public function toString():String {
			return "[SwfElementAS2]";
		}

	}
