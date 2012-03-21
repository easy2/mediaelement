
package htmlelements 
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.media.ID3Info;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundLoaderContext;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.display.Sprite;
	import flash.events.SecurityErrorEvent;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.media.SoundMixer;
	import flash.system.Security;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.display.AVM1Movie;



	/**
	* ...
	* @author DefaultUser (Tools -> Custom Arguments...)
	*/
	public class SwfElement extends Sprite implements IMediaElement
	{

		private var _sound:Sound;
		private var _soundTransform:SoundTransform;

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

		private var _element:FlashMediaElement;
		private var _firedCanPlay:Boolean = false;
		private var _playAfterLoading:Boolean= false;
		
		private var _swfContent:MovieClip;
		private var _swfWidth:Number;
		private var _swfHeight:Number;
		private var _swfCurrentFrame:int = 1;
		private var _swfTotalFrames:int;
		private var _isAVM1Movie:Boolean = false;

		public function duration():Number {
			return _duration;
		}

		public function currentTime():Number {
			return _currentTime;
		}
		
		public function currentProgress():Number {
				return Math.round(_bytesLoaded/_bytesTotal*100);
		}

		public function SwfElement(element:FlashMediaElement, autoplay:Boolean, preload:String, timerRate:Number, startVolume:Number) 
		{
			_element = element;
			_autoplay = autoplay;
			_volume = startVolume;
			_preload = preload;

			_soundTransform = new SoundTransform(_volume);
		}

		// events
		private function handleSwfLoadProgress(e:ProgressEvent):void {
			_bytesLoaded = e.bytesLoaded;
			_bytesTotal = e.bytesTotal;
			sendEvent(HtmlMediaEvent.PROGRESS);
		}
		private function handleErrors(e:Event = null):void {
			//do nothing, load has failed!
		}
		private function handleSwfLoadComplete(e:Event):void {
			_isLoaded = true;
			
			var contentLoaderInfo:LoaderInfo = e.target as LoaderInfo;
			
			//read form loader info to get file width and height, not the total width (which includes animating from off stage)
			_swfWidth = contentLoaderInfo.width;
			_swfHeight = contentLoaderInfo.height;
			
			if(contentLoaderInfo.loader.content is AVM1Movie) {
				_isAVM1Movie = true;
				addChild(contentLoaderInfo.loader);
				sendEvent(HtmlMediaEvent.LOADEDDATA);
				sendEvent(HtmlMediaEvent.CANPLAY);
				didStartPlaying();
				//there's not much we can do here
				return;
			}
			
			_swfContent = contentLoaderInfo.loader.content as MovieClip;
			
			_swfTotalFrames = _swfContent.totalFrames; 

			if(_swfContent) {
				_swfContent.gotoAndStop(1);
				_swfContent.addEventListener(Event.ENTER_FRAME, handleFrameEnter);
				addChild(_swfContent);
				
				_duration = (_swfContent.stage != null) ? _swfTotalFrames/_swfContent.stage.frameRate : 0;
				
				sendEvent(HtmlMediaEvent.LOADEDDATA);
				sendEvent(HtmlMediaEvent.CANPLAY);
				_firedCanPlay = true;
				
				if (_playAfterLoading) {
					_playAfterLoading = false;
					play();
				}	
			} else {
				handleErrors();
			}
		}
		private function handleFrameEnter(e:Event):void {
			_swfCurrentFrame = _swfContent.currentFrame;
			_currentTime = (_swfContent.stage !=  null) ? _swfCurrentFrame / _swfContent.stage.frameRate : 0;
			if(!_isPaused) {
				sendEvent(HtmlMediaEvent.TIMEUPDATE);
				if(_swfCurrentFrame >= _swfTotalFrames) {
					_currentTime = 0;
					_isEnded = true;
		
					sendEvent(HtmlMediaEvent.ENDED);
				}
			}
		}
		//events


		// METHODS
		public function setSrc(url:String):void {
			_currentUrl = url;
			_isLoaded = false;
		}

		public function load():void {
			if (_currentUrl == "")
				return;
			
			_currentUrl = "http://webapps.qa/myopsui/ps_jobs/lowe200009/publish/live/media/slide1_20123614324807.swf";
			
			_currentTime = 0;
			_swfCurrentFrame = 1;
			
			var swfLoader:Loader = new Loader();
			swfLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleSwfLoadComplete);
			swfLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, handleErrors);
			swfLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleErrors);
			swfLoader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, handleSwfLoadProgress);
			swfLoader.load(new URLRequest(_currentUrl), new LoaderContext(true, null, SecurityDomain.currentDomain));
			
			sendEvent(HtmlMediaEvent.LOADSTART);
		}

		public function play():void {
			if (!_isLoaded) {
				_playAfterLoading = true;
				load();
				return;
			}
			_isPaused = false;
			_swfContent.gotoAndPlay(_swfCurrentFrame);
			didStartPlaying();
		}

		public function pause():void {
			if(!_isAVM1Movie) {
				_swfContent.stop();
				_isPaused = true;
				sendEvent(HtmlMediaEvent.PAUSE);
			}
		}

		public function stop():void {
			if(!_isAVM1Movie) {
				_swfContent.stop();
				_isPaused = true;
				sendEvent(HtmlMediaEvent.STOP);
			}
		}

		public function setCurrentTime(pos:Number):void {
			if(!_isAVM1Movie) {
				_currentTime = pos;
				_swfCurrentFrame = (_swfContent.stage != null) ? Math.round(_swfContent.stage.frameRate * _currentTime) : 1;
				_swfCurrentFrame = Math.max(Math.min(_swfCurrentFrame, _swfTotalFrames), 1);
				_swfContent.gotoAndPlay(_swfCurrentFrame);
				_isPaused = false;
				didStartPlaying();
			}
		}
		
		private function didStartPlaying():void {
			_isPaused = false;
			sendEvent(HtmlMediaEvent.PLAY);
			sendEvent(HtmlMediaEvent.PLAYING);
			
			if (!_firedCanPlay) {
				sendEvent(HtmlMediaEvent.LOADEDDATA);
				sendEvent(HtmlMediaEvent.CANPLAY);				
				_firedCanPlay = true;
			}
		}
		
		public function setVolume(volume:Number):void {
			_volume = volume;
			_soundTransform.volume = volume;

			SoundMixer.soundTransform  = _soundTransform;

			_isMuted = (_volume == 0);

			sendEvent(HtmlMediaEvent.VOLUMECHANGE);
		}
		
		public function getVolume():Number {
			if(_isMuted) {
				return 0;
			} else {
				return _volume;
			}
		}

		public function setMuted(muted:Boolean):void {

			// ignore if already set
			if ( (muted && _isMuted) || (!muted && !_isMuted))
				return;

			if (muted) {
				_preMuteVolume = _soundTransform.volume;
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

}
