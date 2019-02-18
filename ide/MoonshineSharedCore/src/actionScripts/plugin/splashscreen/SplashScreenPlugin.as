
////////////////////////////////////////////////////////////////////////////////
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0 
// 
// Unless required by applicable law or agreed to in writing, software 
// distributed under the License is distributed on an "AS IS" BASIS, 
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and 
// limitations under the License
// 
// No warranty of merchantability or fitness of any kind. 
// Use this software at your own risk.
// 
////////////////////////////////////////////////////////////////////////////////
package actionScripts.plugin.splashscreen
{
    import flash.events.Event;
    import mx.collections.ArrayCollection;
    import actionScripts.plugin.IMenuPlugin;
    import actionScripts.plugin.PluginBase;
    import actionScripts.plugin.settings.ISettingsProvider;
    import actionScripts.plugin.settings.vo.BooleanSetting;
    import actionScripts.plugin.settings.vo.ISetting;
    import actionScripts.ui.IContentWindow;
    import actionScripts.ui.menu.vo.MenuItem;
    import actionScripts.utils.UtilsCore;
    
    import components.views.splashscreen.SplashScreen;

	public class SplashScreenPlugin extends PluginBase implements IMenuPlugin, ISettingsProvider
	{
		override public function get name():String			{ return "Splash Screen Plugin"; }
		override public function get author():String		{ return "Moonshine Project Team"; }
		override public function get description():String	{ return "Shows artsy splashscreen"; }
		
		public static const EVENT_SHOW_SPLASH:String = "showSplashEvent";
		
		[Bindable]
		public var showSplash:Boolean = true;

		[Bindable]
		public var projectsTemplates:ArrayCollection = new ArrayCollection();

		override public function activate():void
		{
			super.activate();
			
			if (showSplash)
			{				
				showSplashScreen();
			}
			
			dispatcher.addEventListener(EVENT_SHOW_SPLASH, handleShowSplash);
		}
		
		override public function deactivate():void
		{
			super.deactivate();
			
			dispatcher.removeEventListener(EVENT_SHOW_SPLASH, handleShowSplash);
		}
		
		public function getMenu():MenuItem
		{
			// Since plugin will be activated if needed we can return null to block menu
			if( !_activated ) return null;
			
			return UtilsCore.getRecentProjectsMenu();
		}
		
		public function getSettingsList():Vector.<ISetting>
		{
			return Vector.<ISetting>([
				new BooleanSetting(this, 'showSplash', 'Show splashscreen at startup')
			])
		}

		override public function dispatchEvent(event:flash.events.Event):Boolean
		{
			return dispatcher.dispatchEvent(event);
		}

		protected function handleShowSplash(event:Event):void
		{
			showSplashScreen();
		}

        private function showSplashScreen():void
        {
            // Don't add another splash if one is up already
            for each (var tab:IContentWindow in model.editors)
            {
                if (tab is SplashScreen) return;
            }

			var splashScreen:SplashScreen = new SplashScreen();
			splashScreen.plugin = this;

            model.editors.addItem(splashScreen);
        }
    }
}