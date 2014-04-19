module Tomiko
  require "capybara/dsl"
  require "capybara/poltergeist"

  # By default Capybara will try to boot a rack application
  # automatically. You might want to switch off Capybara's
  # rack server if you are running against a remote application
  Capybara.run_server = false
  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app, {
      # Raise JavaScript errors to Ruby
      js_errors: false,
      # Additional command line options for PhantomJS
      phantomjs_options: ['--ignore-ssl-errors=yes'],
    })
  end
  Capybara.current_driver = :poltergeist

  class Scraper
    include Capybara::DSL

    ASIAONE_URL = "http://forex.asiaone.com.sg/"
    FROM_CURRENCIES = %w{ CNY MYR USD VND }

    def initalize
      page.driver.resize(1024, 768)
      page.driver.headers = {
        'User-Agent' => 'Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1667.0 Safari/537.36',
      }
    end

    def scrape
      FROM_CURRENCIES.each do |c|
        do_scrape c
        sleep 1 # stay under the radar
      end
    end

    private

    def do_scrape from_currency
      visit ASIAONE_URL
      if request_success?
        within 'form#currency' do
          fill_in :unit, with: '1.00'
          select_by_value :from, from_currency
          select_by_value :into, 'SGD'
          click_on 'Submit'
        end
        page.driver.save_screenshot screenshot_output_path(from_currency), full: true
      else
        raise "#{ASIAONE_URL} is down!"
      end
    end

    def request_success?
      page.driver.status_code == 200
    end

    def select_by_value name, value
      option_xpath = "//*[@name='#{name}']/option[@value='#{value}']"
      option = find(:xpath, option_xpath).text
      select option, from: name
    end

    def screenshot_output_path from_currency
      "screenshots/#{from_currency}_SGD_#{Time.now.strftime('%Y%m%d')}.png".tap do |p|
        FileUtils.mkdir_p File.dirname(p)
      end
    end
  end
end
