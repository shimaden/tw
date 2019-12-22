# encoding: UTF-8
require 'delegate'

#============================================================================
# 行指向でテキスト・ファイルにセーブ、ロードできる配列クラス
#============================================================================
class FileSavableArray < DelegateClass(Array)

  #------------------------------------------------
  # イニシャライザ
  # filename  : キャッシュのファイル名
  # permission: キャッシュ・ファイルのパーミッション
  #------------------------------------------------
  def initialize(filename, permission)
    super(Array.new)
    @filename   = filename
    @permission = permission
  end

  #------------------------------------------------
  # 配列にキャッシュ・ファイルの内容を読み込む。
  # 読み込む前に配列の内容はクリアされる。
  #
  # File::LOCK_SH 共有ロック。他のユーザは書き込めない。読み取りは可能。
  #------------------------------------------------
    def load_from_file()
      lock_mode = File::LOCK_SH   # 共有ロック

      if self.file_exist? then
        File.open(@filename, "r") do |f|
          f.flock(lock_mode)
          self.clear()
          while line = f.gets do
            self.push(line.chomp)
          end
        end
      end
    end


  #------------------------------------------------
  # 配列の内容をキャッシュ・ファイルに保存。
  # これを実行すると
  # http://docs.ruby-lang.org/ja/1.9.3/method/File/i/flock.html
  #
  # File::LOCK_EX 排他的ロック。他のユーザは読み書きできない。
  #------------------------------------------------
  def save_to_file()
    open_permission = File::RDWR | File::CREAT
    lock_mode       = File::LOCK_EX   # 排他ロック

    File.open(@filename, open_permission , @permission) do |f|
      f.flock(lock_mode)
      self.each do |elem|
        f.puts elem.to_s
      end
    end
  end

  #------------------------------------------------
  # ファイルが存在するか
  #------------------------------------------------
  def file_exist?()
    return File.exist?(@filename)
  end

    #------------------------------------------------
  protected
    #------------------------------------------------

  #------------------------------------------------
  # アクセサ
  #------------------------------------------------
  def filename
    @filename
  end

end

#============================================================================
# 行指向でテキスト・ファイルにキャッシュできる配列クラス
#============================================================================
class FileCashableArray < FileSavableArray

  #------------------------------------------------
  # イニシャライザ
  # filename: キャッシュのファイル名
  # permission    : キャッシュ・ファイルのパーミッション
  # interval: キャッシュ・ファイルを更新するまでの時間（秒）
  #           FileCashableArray は、要素の参照が要求された時、キャッシュ・
  #           ファイルに蓄えられたデータを返す。
  #           しかし、キャッシュ・ファイルの最終更新時刻にこ interval を
  #           足した時刻が現在時刻より過去である場合、FileCashableArray は
  #           一旦どこからかデータを取得し、FileCashableArray 自身を
  #           そのデータで更新し、キャッシュ・ファイルにそのデータを
  #           保存する。
  #------------------------------------------------
  def initialize(filename, permission, interval)
    super(filename, permission)
    @interval = interval
  end

  #------------------------------------------------
  # ファイルが古いか（ファイルが存在しない場合も古いとみなす）
  #------------------------------------------------
  def file_old?()
    if self.file_exist?() then
      mtime = File.mtime(@filename)
      return mtime + @interval < Time.now
    else
      return true
    end
  end

    #------------------------------------------------
  public
    #------------------------------------------------

  #------------------------------------------------
  # []
  #------------------------------------------------
  def [](*a)
    self.hook()
    return __getobj__[*a]
  end

  #------------------------------------------------
  # at()
  #------------------------------------------------
  def at(nth)
    self.hook()
    return __getobj__.at(nth)
  end

  #------------------------------------------------
  # assoc(key)
  #------------------------------------------------
  def assoc(key)
    self.hook()
    return __getobj__.assoc(key)
  end

  #------------------------------------------------
  # clone()
  #------------------------------------------------
  def clone()
    self.hook()
    return __getobj__.clone()
  end

  #------------------------------------------------
  # dup()
  #------------------------------------------------
  def dup()
    self.hook()
    return __getobj__.dup()
  end

  #------------------------------------------------
  # each()
  #------------------------------------------------
  def each()
    self.hook()
    if block_given? then
      __getobj__.each do |val|
        yield(val)
      end
      return self
    else
      return __getobj__.each
    end
  end

  #------------------------------------------------
  # fetch(nth)
  # fetch(nth, ifnone)
  # fetch(nth) { |nth} ... }
  #------------------------------------------------
  def fetch(nth, *args)
    self.hook()
    if block_given? then
      ret = __getobj__.fetch(nth) do |val|
        yield(val)
      end
      return ret
    else
      return __getobj__.fetch(nth, *args)
    end
  end

  #------------------------------------------------
  # join(sep = $,)
  #------------------------------------------------
  def join(sep = $,)
    self.hook()
    return __getobj__.join(sep)
  end

  #------------------------------------------------
  # first
  #------------------------------------------------
  def first(*n)
    self.hook()
    return __getobj__.first(*n)
  end

  #------------------------------------------------
  # last
  #------------------------------------------------
  def last(n = 1)
    self.hook()
    return __getobj__.last(*n)
  end

  #------------------------------------------------
  # length
  #------------------------------------------------
  def length()
    self.hook()
    return __getobj__.length()
  end

  #------------------------------------------------
  # size
  #------------------------------------------------
  def size()
    self.hook()
    return __getobj__.size()
  end

  #------------------------------------------------
  # to_s()
  #------------------------------------------------
  def to_s()
    self.hook()
    return __getobj__.to_s()
  end

  #------------------------------------------------
  # inspect()
  #------------------------------------------------
  def inspect()
    self.hook()
    return __getobj__.inspect()
  end

  #------------------------------------------------
  # last_update_time
  #------------------------------------------------
  def last_update_time()
    return File.mtime(@filename)
  end
 
    #------------------------------------------------
  protected
    #------------------------------------------------

  #------------------------------------------------
  # Hook (Template method)
  #------------------------------------------------
  def hook(*a)
  end

end


# RubyのDelegatorを使ってみる話
# http://miz-log.blogspot.jp/2012/07/rubydelegator.html

