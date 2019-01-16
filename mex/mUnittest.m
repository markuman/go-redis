function ret = mUnittest(script)
%mUnittest - uniform unittest framework for GNU Octave and Matlab
% the created .xml Reports are designed to work with Jenkins JUnit publisher
% The MIT License (MIT) https://github.com/markuman/mUnittest

    if ischar(script)
        
        % set 'script' as testName
        className(script);
        fprintf('\n\n mUnittest: %s \n\n', className())
        
        % start time 
        tic
        try
            % call testscript
            eval(script);
            ret = 0;
        catch
            ret = 1;         
        end
        
        % print summary
        if (summary())
            ret = 0;
        else
            ret = 1;
        end
    else
        ret = 1;        
    end%if

end%function mUnittest

function ret = summary()

    % get number of passed and failed tests
    result = assert();    
    assert('this', 'will', 'end', 'here', ':-)');
    
    
    f   = result.countFailed;
    p   = result.countPassed;
    num = result.countTests;
    t   = result.t;
    xml = result.xml;
    
    % report numbers
    fprintf('\n\n PASSED %d OF %d \n\n', p, p + f);
    
    % write report
    
    fid = fopen(sprintf('%sReport.xml', className()), 'w');
        fprintf(fid, '<testsuite tests="%d" time="%.f">%s\n</testsuite>',num, t, xml);    
    fclose(fid);

    ret = f == 0;
    
end

% overloaded assert
function ret = assert(cond, msg, errormsg, successmsg, varargin)

    persistent t
    persistent countTests
    persistent countFailed
    persistent countPassed
    persistent countBlocks
    persistent xml


    if (nargin == 5)
    
      [t, countTests, countFailed, countPassed, countBlocks] = deal(0);
      xml = '';
      protectCount('this', 'will', 'end', 'here', ':-)');
    
    elseif (nargout == 1)
        % five inputs will clear all variables and flush the xml file
        
        % return results
        ret.t = t;
        ret.countTests  = countTests;
        ret.countFailed = countFailed;
        ret.countPassed = countPassed;
        ret.countBocks  = countBlocks;
        ret.xml         = xml;
        
        % reset everything
        builtin('clear', 't');
        builtin('clear', 'countTests');
        builtin('clear', 'countFailed');
        builtin('clear', 'countPassed');
        builtin('clear', 'countBlocks');
        builtin('clear', 'xml');
          
    else
        
        if isempty(t), t = 0; end
        if isempty(countTests), countTests = 0; end
        if isempty(countFailed), countFailed = 0; end
        if isempty(countPassed), countPassed = 0; end
        if isempty(countBlocks), countBlocks = 0; end
        if isempty(xml), xml = ''; end

        this_time = toc - t;

        % increase number of sings tests (asserts)
        countTests = countTests + 1;

        % set passed and failed messages
        if nargin <= 1        
            msg = sprintf('%s_%d', className(), countTests);
        end
        if nargin <= 2
            errormsg = msg;
        end
        if nargin <= 3
            successmsg = [];
        end


        if cond
            %% PASSED        
            % increase number of passed tests
            countPassed = countPassed + 1;

            % verbose output
            fprintf('\n%d \t ✓ \t %s', countTests, msg)

            % concatinate global string for xml output
            xml = [xml sprintf('\n\t<testcase classname="%s #%d " name="%s" time="%.2f">', className(), protectCount() , msg, this_time)];
            
        elseif cond == -1
            %% SKIP
            % TODO
            
            
        else
            %% FAILED
            % increase number of failed tests
            countFailed = countFailed + 1;

            % verbose output
            fprintf('\n%d \t X \t %s', countTests, errormsg)

            % concatinate global string for xml output
            xml  = [xml sprintf('\n\t<testcase classname="%s #%d " name="%s" time="%.2f" >\n\t\t<failure type="assert"> %s </failure>', className(), protectCount(), msg, t, errormsg)];
            
        end
        
        % system out for additional informations
        if isempty(successmsg)
            xml = [xml sprintf('\n\t</testcase>')];
        else
            xml = [xml sprintf('\n\t\t<system-out> %s </system-out>\n\t</testcase>', successmsg)];
        end
    
        t = toc;
    end

end%function assert

function ret = className(name)

    persistent n
    if nargin == 1
        n = name;
        ret = true;
    elseif nargout == 1
        ret = n;
    else
        ret = false;
    end

end%function className

function clear()

    protectCount(1);
    evalin('caller', 'builtin(''clear'')')
    
end%function

function ret = protectCount(in, varargin)

    persistent n
    if isempty(n), n = 0; end
    
    if nargin == 1
        n = n + in;
    elseif nargout == 1
        ret = n;
    elseif nargin == 5
        n = 0;
    else
        ret = n;
    end

end%function
