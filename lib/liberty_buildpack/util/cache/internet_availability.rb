# Encoding: utf-8
# IBM WebSphere Application Server Liberty Buildpack
# Copyright IBM Corp. 2014, 2015
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'liberty_buildpack/diagnostics/logger_factory'
require 'liberty_buildpack/util/cache'
require 'liberty_buildpack/util/configuration_utils'
require 'monitor'
require 'singleton'

module LibertyBuildpack
  module Util
    module Cache

      # Maintains the current state of internet availability.
      class InternetAvailability
        include ::Singleton

        # Creates a new instance.  Availability is assumed to be +true+ unless +remote_downloads+ is set to +disabled+
        # in +config/cache.yml+.
        def initialize
          @logger  = LibertyBuildpack::Diagnostics::LoggerFactory.get_logger
          @monitor = Monitor.new
          @monitor.synchronize { @available = remote_downloads? }
        end

        # Returns whether the internet is available
        #
        # @return [Boolean] +true+ if the internet is available, +false+ otherwise
        def available?
          @monitor.synchronize { @available }
        end

        # Sets whether the internet is available
        #
        # @param [Boolean] available whether the internet is available
        # @param [String, nil] message an optional message to be printed when the availability is set
        # @yield an environment with internet availability temporarily overridden if block given
        def available(available, message = nil)
          @monitor.synchronize do
            if block_given?
              preserve_availability do
                @available = available
                @logger.warn { "Internet availability temporarily set to #{available}: #{message}" } if message

                yield
              end
            else
              @available = available
              @logger.warn { "Internet availability set to #{available}: #{message}" } if message
            end
          end
        end

        private

        def remote_downloads?
          LibertyBuildpack::Util::ConfigurationUtils.load('cache')['remote_downloads'] != 'disabled'
        end

        def preserve_availability
          previous = @available
          begin
            yield
          ensure
            @available = previous
          end
        end

      end

    end
  end
end
