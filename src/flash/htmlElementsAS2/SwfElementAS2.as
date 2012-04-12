﻿import htmlElementsAS2.HtmlMediaEventAS2;
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
		private var _swfCurrentFrame:Number = 1;
		private var _swfTotalFrames:Number;
		private var _shouldCenter:Boolean = true;
		
		private var _frameRate:Number = 30;
		
		private var _holder:MovieClip;
		
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
			_element = element;
			_autoplay = autoplay;
			_volume = startVolume;
			_preload = preload;

			_sound = new Sound();
			setVolume(_volume);

			_holder = holder;
		}
		
		// events
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
			
			if(_swfContent) {
				_swfContent.gotoAndStop(1);
				_swfContent.addEventListener("onEnterFrame", handleFrameEnter, this);
				
				_duration =  _swfTotalFrames/_frameRate;
				
				sendEvent(HtmlMediaEventAS2.LOADEDDATA);
				sendEvent(HtmlMediaEventAS2.CANPLAY);
				_firedCanPlay = true;
				if (_playAfterLoading == true) {
					_isPaused = false;
					_swfContent.gotoAndPlay(_swfCurrentFrame);
					didStartPlaying();
				}	
			} else {
				onLoadError();
			}
		}
		
		private function handleFrameEnter():Void {
			_swfCurrentFrame = _swfContent._currentframe;
			_currentTime =_swfCurrentFrame / _frameRate;
			if(!_isPaused) {
				sendEvent(HtmlMediaEventAS2.TIMEUPDATE);
				if(_swfCurrentFrame >= _swfTotalFrames) {
					_currentTime = 0;
					_isEnded = true;
		
					sendEvent(HtmlMediaEventAS2.ENDED);
				}
			}
		}
		//events


		// METHODS
		public function setSrc(url:String):Void {
			_currentUrl = url;
			_isLoaded = false;
		}

		public function load():Void {
			if (_currentUrl == "")
				return;
		
			_currentTime = 0;
			_swfCurrentFrame = 1;
			
			var swfLoader:MovieClipLoader = new MovieClipLoader();
			swfLoader.addListener(this);
			swfLoader.loadClip(_currentUrl, _holder);
			
			sendEvent(HtmlMediaEventAS2.LOADSTART);
		}

		public function play():Void {
			if (!_isLoaded) {
				load();
				return;
			}
			
			_isPaused = false;
			_swfContent.gotoAndPlay(_swfCurrentFrame);
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
			_swfCurrentFrame = Math.round(_frameRate * _currentTime);
			_swfCurrentFrame = Math.max(Math.min(_swfCurrentFrame, _swfTotalFrames), 1);
			_swfContent.gotoAndPlay(_swfCurrentFrame);
			_isPaused = false;
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

	}


