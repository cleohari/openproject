#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Users
      class UserAvatarAPI < ::API::OpenProjectAPI
        helpers ::AvatarHelper
        helpers ::API::Helpers::AttachmentRenderer

        helpers do
          def set_cache_headers!
            return if @user == current_user

            # Cache for one day if not the current user
            expire_in = 60 * 60 * 24
            header "Cache-Control", "public, max-age=#{expire_in}"
            header "Expires", CGI.rfc1123_date(Time.now.utc + expire_in)
          end
        end

        get '/avatar' do
          set_cache_headers!

          if local_avatar = local_avatar?(@user)
            respond_with_attachment(local_avatar)
          elsif avatar_manager.gravatar_enabled?
            redirect build_gravatar_image_url(@user)
          else
            status 404
          end
        rescue StandardError => e
          # Exceptions may happen due to invalid mails in the avatar builder
          # but we ensure that a 404 is returned in that case for consistency
          Rails.logger.error { "Failed to render #{@user&.id} avatar: #{e.message}" }
          status 404
        end
      end
    end
  end
end
