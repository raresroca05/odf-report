require 'rubygems'
require 'zip'
require 'date'
require 'fileutils'
require 'nokogiri'
require 'set'
require 'mime/types'
require 'active_support'
require 'active_support/core_ext'
require 'builder'
require 'i18n'

I18n.load_path += Dir.glob( File.dirname(__FILE__) + '/locales/*.{rb,yml}' )

require File.expand_path('../odf-report/parser/default',  __FILE__)

require File.expand_path('../odf-report/image',    __FILE__)
require File.expand_path('../odf-report/images',    __FILE__)
require File.expand_path('../odf-report/field',     __FILE__)
require File.expand_path('../odf-report/text',      __FILE__)
require File.expand_path('../odf-report/link',      __FILE__)
require File.expand_path('../odf-report/file',      __FILE__)
require File.expand_path('../odf-report/nested',    __FILE__)
require File.expand_path('../odf-report/section',   __FILE__)
require File.expand_path('../odf-report/poorman_section',   __FILE__)
require File.expand_path('../odf-report/table',     __FILE__)
require File.expand_path('../odf-report/report',    __FILE__)
require File.expand_path('../odf-report/calendar',  __FILE__)
