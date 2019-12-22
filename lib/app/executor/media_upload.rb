# encoding: UTF-8
# このファイルはＵＴＦ－８です。
module Tw::App

  class Executor < AbstractExecutor
    #----------------------------------------------------------------
    # Upload media.
    #
    # file: File or Hasn
    #
    # Return value:
    #   media_id: Integer
    #----------------------------------------------------------------
    def media_upload(file, options)
      begin
        self.client.new_auth(@account)
        media_id = self.client.upload_media(file, options)
      rescue Tw::Error=> e
        if @options.force? then
          media_id = nil
        else
          raise
        end
      end
      return media_id
    end

    #----------------------------------------------------------------
    # Upload multiple media specified filenames in file_name_array.
    # Return
    #   media_id in CSV.
    #----------------------------------------------------------------
    def upload_multiple_media(file_name_array, additional_owners = nil)
      ret = nil
      if file_name_array.size > 0 then
        media_ids = file_name_array.map {|fname|
          File.open(fname, "r")
        }.map {|media_file|
          self.media_upload(media_file, additional_owners)
        }
        ret = media_ids.join(",")
      end
      return ret
    end

    #----------------------------------------------------------------
    # Upload a video file.
    # filename: file name of a video file.
    # media_type: media type like "video/mp4"
    # media_category: "tweet_image", "tweet_gif" (animetad GIF only)
    #                 or "tweet_video".
    #----------------------------------------------------------------
    def upload_video(filename, media_type, media_category, additional_owners = nil)
      # INIT
      max_segment_size = 5337999
      File.open(filename, "rb") do |f|
        size = f.size
$stderr.puts("INIT file size: #{size}")
        init_result = self.client.upload_video_init(media_type, size,
                              media_category, additional_owners)
$stderr.puts("INIT Result: #{init_result}")

        # APPEND
        segment_index = 0 # What is this?
        append_result = self.client.upload_video_append(
                          f, init_result[:media_id], segment_index)
$stderr.puts("APPEND: (no return value)")

        # FINALIZE
        finalize_result = self.client.upload_video_finalize(init_result[:media_id])
$stderr.puts("FINALIZE Result: #{finalize_result}")
        processing_info = finalize_result[:processing_info]
        if processing_info && processing_info[:state] == "pending" then
          wait_sec = processing_info[:check_after_secs]
        else
          return finalize_result
        end

        # STATUS
        # When polling is required.
        state = "in_progress" # It can take "succeeded" and "failed".
        while state == "in_progress" do
          sleep(wait_sec)
          status_result = self.client.upload_video_status(init_result[:media_id])
$stderr.puts("STATUS Result: #{status_result}")
          state    = status_result[:processing_info][:state]
          if state == "in_progress" then
            wait_sec = status_result[:processing_info][:check_after_secs]
            percent  = status_result[:processing_info][:progress_percent]
          end
        end
$stderr.puts("-- Video upload end ---")

        return status_result
        # finalize_result:
        # {
        #   :media_id=>623998290850230272,
        #   :media_id_string=>"623998290850230272",
        #   :size=>4320649,
        #   :expires_after_secs=>3600,
        #   :video=>{
        #     :video_type=>"video/mp4"
        #   }
        # }

        # status_result:
        # Example of an in_progress response:
        #
        # {
        #   "media_id":710511363345354753,
        #   "media_id_string":"710511363345354753",
        #   "expires_after_secs":3595,
        #   "processing_info":{
        #     "state":"in_progress", // state transition flow is pending -> in_progress -> [failed|succeeded]
        #     "check_after_secs":10, // check for the update after 10 seconds
        #     "progress_percent":8 // Optional [0-100] int value. Please don't use it as a replacement of "state" field.
        #   }
        # }
        #   
        # Example of a failed response:
        #   
        # {
        #   "media_id":710511363345354753,
        #   "media_id_string":"710511363345354753",
        #   "processing_info":{
        #     "state":"failed",
        #     "progress_percent":12,
        #     "error":{
        #       "code":1,
        #       "name":"InvalidMedia",
        #       "message":"Unsupported video format"
        #     }
        #   }
        # }
        #   
        # Example of a succeeded response:
        #   
        # {
        #   "media_id":710511363345354753,
        #   "media_id_string":"710511363345354753",
        #   "expires_after_secs":3593,
        #   "video":{
        #     "video_type":"video\/mp4"
        #   },
        #   "processing_info":{
        #     "state":"succeeded",
        #     "progress_percent":100,
        #   }
        # }
      end
    end

  end

end
