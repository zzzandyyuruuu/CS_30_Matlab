classdef ExperimentsWithMATLABApp < handle
    %
    % Usage:
    %     app.ExperimentsWithMATLABApp
    
    properties
        AppHandle;
        AppCount = 0;
        Output;
        CurrClass;
    end
    
    properties (Constant)
        AppPathBase = {'/ExperimentsWithMATLAB/code'};
        AppClass = 'ExperimentsWithMATLABApp';
        Increment = 1;
        Decrement = 0;
        Version = '13a';
    end
    
    properties (Dependent)
        AppPath;
    end
    
    methods (Static)
        function count = refcount(increment)
            persistent AppCount;
            if(isempty(AppCount))
                AppCount = 1;
            else
                if(increment)
                    AppCount = plus(AppCount,1);
                else
                    AppCount = minus(AppCount,1);
                    if AppCount < 0
                        AppCount = 0;
                    end
                end
            end
            count = AppCount;
        end
    end
    
    methods
        % Create the application object
        function obj = ExperimentsWithMATLABApp()
            obj.CurrClass = metaclass(obj);
            startApp(obj)
        end
        
        function value = get.AppPath(obj)
            appview = com.mathworks.appmanagement.AppManagementViewSilent;
            appAPI = com.mathworks.appmanagement.AppManagementApiBuilder.getAppManagementApiCustomView(appview);
            
            myAppsLocation = char(appAPI.getMyAppsLocation);
            
            value = cellfun(@(x) fullfile(myAppsLocation, x), obj.AppPathBase, 'UniformOutput', false);
        end
        
        % Start the application
        function startApp(obj)
            % Increment the reference count by one and lock the file
            mlock;
            ExperimentsWithMATLABApp.refcount(obj.Increment);
            
            % Verify we are about to execute the correct function - if not we
            % should error and exit now.  We need to make sure the paths are
            % equal using canonical paths.
            existVal = exist(fullfile(pwd,'exmapp')); %#ok<EXIST>
            doesShadowExist = existVal >= 2 && existVal <= 6;
            
            pathOne = java.io.File(pwd);
            pathOne = pathOne.getCanonicalPath();
            pathTwo = java.io.File(obj.AppPath{1});
            pathTwo = pathTwo.getCanonicalPath();
            
            if (doesShadowExist && ~pathOne.equals(pathTwo))
                % We are trying to execute the wrong exmapp
                errordlg(message('MATLAB:apps:runapp:WrongEntryPoint', 'exmapp').getString, ...
                    message('MATLAB:apps:runapp:WrongEntryPointTitle').getString);
                appinstall.internal.stopapp([],[],obj)
                return;
            end
            
            % Must load function (force by using function handle) or nargout lies.
            % Check if the app is a GUIDE app
            if nargout(@exmapp) == 0
                eval('exmapp');
            else
                obj.AppHandle = eval('exmapp');
            end
            
            if(ishandle(obj.AppHandle))
                % Traditional graphics handle based app
                obj.attachOncleanupToFigure(obj.AppHandle);
            elseif isa(obj.AppHandle, 'matlab.apps.AppBase')
                % appdesigner based app
                obj.attachOncleanupToFigure(appdesigner.internal.service.AppManagementService.getFigure(obj.AppHandle));
            elseif isa(obj.AppHandle,'handle') && ~isvalid(obj.AppHandle)
                % Cleanup in the case where the handle was invalidated before here
                appinstall.internal.stopapp([],[],obj)
            else
                % There will be no call to stopapp, instead decrease the refcount
                % now to prevent future clearing issues
                ExperimentsWithMATLABApp.refcount(obj.Increment);
                munlock;
            end
        end
        
        function attachOncleanupToFigure(obj, fig)
            % Setup cleanup code on figure handle using onCleanup object
            cleanupObj = onCleanup(@()appinstall.internal.stopapp([],[],obj));
            appdata = getappdata(fig);
            appfields = fields(appdata);
            found = cellfun(@(x) strcmp(x,'AppCleanupCode'), appfields);
            if(~any(found))
                setappdata(fig, 'AppCleanupCode', cleanupObj);
            end
        end
    end
end
