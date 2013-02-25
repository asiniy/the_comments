# coding: UTF-8
# DOC:
# We use Helper Methods for tree building,
# because it's faster than View Templates and Partials

# SECURITY note
# Prepare your data on server side for rendering
# or use h.html_escape(node.content)
# for escape potentially dangerous content
module RenderCommentsTreeHelper
  module Render 
    class << self
      attr_accessor :h, :options

      # Main Helpers
      def controller
        @options[:controller]
      end

      def t str
        controller.t str
      end

      # Render Helpers
      def visible_draft?
        controller.try(:comments_view_token) == @comment.view_token
      end

      def moderator?
        controller.try(:current_user).try(:comment_moderator?, @comment)
      end

      # Render Methods
      def render_node(h, options)
        @h, @options = h, options
        @comment     = options[:node]

        @max_reply_depth = options[:max_reply_depth] || TheComments.config.max_reply_depth

        if @comment.draft?
          draft_comment
        elsif @comment.published?
          published_comment
        else
          deleted_comment
        end
      end

      def draft_comment
        if visible_draft? || moderator?
          published_comment
        else
          "<li class='draft'>
            <div class='comment draft' id='comment_#{@comment.anchor}'>#{ t('the_comments.waiting_for_moderation') }</div>
            #{ children }
          </li>"
        end
      end

      def published_comment
        "<li>
          <div id='comment_#{@comment.anchor}' class='comment published' data-comment-id='#{@comment.to_param}'>
            <div>
              #{ avatar }
              #{ userbar }
              <div class='cbody'>#{ @comment.content }</div>
              #{ reply }
            </div>
          </div>

          <div class='form_holder'></div>
          #{ children }
        </li>"
      end

      def avatar
        "<div class='userpic'>
          <img src='#{ @comment.avatar_url }' alt='userpic' />
          #{ controls }
        </div>"
      end

      def userbar
        anchor = h.link_to('#', '#comment_' + @comment.anchor)
        title  = @comment.title.blank? ? t('the_comments.guest_name') : @comment.title
        unmoderated = @comment.draft? ? ' unmoderated' : nil

        "<div class='userbar#{unmoderated}'>
          #{ title } #{ anchor }
        </div>"
      end

      def moderator_controls
        if moderator?
          to_spam  = h.link_to t('the_comments.to_spam'),   h.to_spam_comment_url(@comment),  remote: true, class: :to_spam,    method: :post
          to_trash = h.link_to t('the_comments.to_delete'), h.to_trash_comment_url(@comment), remote: true, class: :to_deleted, method: :delete, data: { confirm: t('the_comments.delete_confirm') }

          ctrl = if @comment.draft?
            to_published = h.link_to t('the_comments.to_published'), h.to_published_comment_url(@comment), remote: true, class: :to_published, method: :post
            [to_published, to_spam, to_trash]
          else
            to_draft = h.link_to t('the_comments.to_draft'), h.to_draft_comment_url(@comment), remote: true, class: :to_draft, method: :post
            [to_draft, to_spam, to_trash]
          end
          ctrl.join(' ')
        end
      end

      def reply
        if @comment.depth < @max_reply_depth
          "<p class='reply'><a href='#' class='reply_link'>#{ t('the_comments.reply') }</a>"
        end
      end

      def controls
        "<div class='controls'>#{ moderator_controls }</div>"
      end

      def children
        "<ol class='nested_set'>#{ options[:children] }</ol>"
      end
    end
  end
end