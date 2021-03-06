package actionScripts.plugins.grails
{
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.NativeProcessExitEvent;
    import flash.events.ProgressEvent;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    
    import actionScripts.events.MavenBuildEvent;
    import actionScripts.events.SettingsEvent;
    import actionScripts.events.ShowSettingsEvent;
    import actionScripts.events.StatusBarEvent;
    import actionScripts.factory.FileLocation;
    import actionScripts.plugin.build.MavenBuildStatus;
    import actionScripts.plugin.core.compiler.GrailsBuildEvent;
    import actionScripts.plugin.groovy.grailsproject.vo.GrailsProjectVO;
    import actionScripts.plugin.settings.ISettingsProvider;
    import actionScripts.plugin.settings.vo.AbstractSetting;
    import actionScripts.plugin.settings.vo.ISetting;
    import actionScripts.plugin.settings.vo.PathSetting;
    import actionScripts.plugins.build.ConsoleBuildPluginBase;
    import actionScripts.utils.HelperUtils;
    import actionScripts.utils.UtilsCore;
    import actionScripts.valueObjects.ComponentTypes;
    import actionScripts.valueObjects.ComponentVO;
    import actionScripts.valueObjects.ConstantsCoreVO;
    import actionScripts.valueObjects.ProjectVO;
    import actionScripts.valueObjects.Settings;

    public class GrailsBuildPlugin extends ConsoleBuildPluginBase implements ISettingsProvider
    {
		private var pathSetting:PathSetting;
		
        public function GrailsBuildPlugin()
        {
            super();
        }

        override public function get name():String
        {
            return "Grails Build Setup";
        }

        override public function get author():String
        {
            return ConstantsCoreVO.MOONSHINE_IDE_LABEL + " Project Team";
        }

        override public function get description():String
        {
            return "Grails Build Plugin. Esc exits.";
        }

        public function get grailsPath():String
        {
            return model ? model.grailsPath : null;
        }

        public function set grailsPath(value:String):void
        {
            if (model.grailsPath != value)
            {
                model.grailsPath = value;
            }
        }

        public function getSettingsList():Vector.<ISetting>
        {
			onSettingsClose();
			pathSetting = new PathSetting(this, 'grailsPath', 'Grails Home', true, grailsPath);
			pathSetting.addEventListener(AbstractSetting.PATH_SELECTED, onSDKPathSelected, false, 0, true);
			
			return Vector.<ISetting>([
				pathSetting
			]);
        }
		
		override public function onSettingsClose():void
		{
			if (pathSetting)
			{
				pathSetting.removeEventListener(AbstractSetting.PATH_SELECTED, onSDKPathSelected);
				pathSetting = null;
			}
		}
		
		private function onSDKPathSelected(event:Event):void
		{
			if (!pathSetting.stringValue) return;
			var tmpComponent:ComponentVO = HelperUtils.getComponentByType(ComponentTypes.TYPE_GRAILS);
			if (tmpComponent)
			{
				var isValidSDKPath:Boolean = HelperUtils.isValidSDKDirectoryBy(ComponentTypes.TYPE_GRAILS, pathSetting.stringValue, tmpComponent.pathValidation);
				if (!isValidSDKPath)
				{
					pathSetting.setMessage("Invalid path: Path must contain "+ tmpComponent.pathValidation +".", AbstractSetting.MESSAGE_CRITICAL);
				}
				else
				{
					pathSetting.setMessage(null);
				}
			}
		}

        override public function activate():void
        {
            super.activate();

			dispatcher.addEventListener(GrailsBuildEvent.BUILD, grailsBuildHandler);
			dispatcher.addEventListener(GrailsBuildEvent.BUILD_RELEASE, grailsBuildReleaseHandler);
			dispatcher.addEventListener(GrailsBuildEvent.BUILD_AND_RUN, grailsBuildAndRunHandler);
			dispatcher.addEventListener(GrailsBuildEvent.CLEAN, grailsCleanHandler);
        }

        override public function deactivate():void
        {
            super.deactivate();

			dispatcher.removeEventListener(GrailsBuildEvent.BUILD, grailsBuildHandler);
			dispatcher.removeEventListener(GrailsBuildEvent.BUILD_RELEASE, grailsBuildReleaseHandler);
			dispatcher.removeEventListener(GrailsBuildEvent.BUILD_AND_RUN, grailsBuildAndRunHandler);
			dispatcher.removeEventListener(GrailsBuildEvent.CLEAN, grailsCleanHandler);
        }

        private function getConstantArguments():Vector.<String>
        {
            var args:Vector.<String> = new Vector.<String>();
            if (Settings.os == "win")
            {
                args.push("/C");
            }
            else
            {
                args.push("-c");
            }

            return args;
        }

		override public function start(args:Vector.<String>, buildDirectory:*):void
		{
            if (nativeProcess.running && running)
            {
                warning("Build is running. Wait for finish...");
                return;
            }

            if (!grailsPath)
            {
                error("Specify path to Grails folder.");
                stop(true);
                dispatcher.dispatchEvent(new SettingsEvent(SettingsEvent.EVENT_OPEN_SETTINGS, "actionScripts.plugins.grails::GrailsBuildPlugin"));
                return;
            }
			
            warning("Starting Grails build...");

			super.start(args, buildDirectory);
			
            print("Grails build directory: %s", buildDirectory.fileBridge.nativePath);
            print("Command: %s", args.join(" "));

            var project:ProjectVO = model.activeProject;
            if (project)
            {
                dispatcher.dispatchEvent(new StatusBarEvent(StatusBarEvent.PROJECT_BUILD_STARTED, project.projectName, "Building "));
                dispatcher.addEventListener(StatusBarEvent.PROJECT_BUILD_TERMINATE, onProjectBuildTerminate);
            }
		}

		private function grailsBuildHandler(event:Event):void
		{
			this.start(new <String>[[UtilsCore.getGrailsBinPath(), "compile"].join(" ")], model.activeProject.folderLocation);
		}

		private function grailsBuildReleaseHandler(event:Event):void
		{
			this.start(new <String>[[UtilsCore.getGrailsBinPath(), "war"].join(" ")], model.activeProject.folderLocation);
		}

		private function grailsBuildAndRunHandler(event:Event):void
		{
			this.start(new <String>[[UtilsCore.getGrailsBinPath(), "run-app"].join(" ")], model.activeProject.folderLocation);
		}

		private function grailsCleanHandler(event:Event):void
		{
			this.start(new <String>[[UtilsCore.getGrailsBinPath(), "clean"].join(" ")], model.activeProject.folderLocation);
		}

        override protected function onNativeProcessIOError(event:IOErrorEvent):void
        {
            super.onNativeProcessIOError(event);
            dispatcher.dispatchEvent(new StatusBarEvent(StatusBarEvent.PROJECT_BUILD_ENDED));
        }

        override protected function onNativeProcessStandardErrorData(event:ProgressEvent):void
        {
			super.onNativeProcessStandardErrorData(event);
			dispatcher.dispatchEvent(new StatusBarEvent(StatusBarEvent.PROJECT_BUILD_ENDED));
		}

        override protected function onNativeProcessExit(event:NativeProcessExitEvent):void
        {
            super.onNativeProcessExit(event);

			if(isNaN(event.exitCode))
			{
				warning("Grails build has been terminated.");
			}
			else if(event.exitCode != 0)
			{
				warning("Grails build has been terminated with exit code: " + event.exitCode);
			}
			else
			{
				success("Grails build has completed successfully.");
			}


			dispatcher.removeEventListener(StatusBarEvent.PROJECT_BUILD_TERMINATE, onProjectBuildTerminate);
            dispatcher.dispatchEvent(new StatusBarEvent(StatusBarEvent.PROJECT_BUILD_ENDED));
        }

        private function onProjectBuildTerminate(event:StatusBarEvent):void
        {
            stop();
        }
	}
}