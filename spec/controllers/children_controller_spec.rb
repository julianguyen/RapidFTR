require 'spec_helper'

def inject_export_generator( fake_export_generator, child_data )
	ExportGenerator.stub!(:new).with(child_data).and_return( fake_export_generator )
end

def stub_out_export_generator child_data = []
	inject_export_generator( stub_export_generator = stub(ExportGenerator) , child_data)
	stub_export_generator.stub!(:child_photos).and_return('')
	stub_export_generator
end

def stub_out_child_get(mock_child = mock(Child))
	Child.stub(:get).and_return( mock_child )
	mock_child
end

describe ChildrenController do

  before :each do
    child_fake_admin_login
  end

  def mock_child(stubs={})
    @mock_child ||= mock_model(Child, stubs).as_null_object
  end

  it 'GET reindex' do
    Child.should_receive(:reindex!).and_return(nil)
    get :reindex
    response.should be_success
  end

  describe '#authorizations' do
    describe 'collection' do
      it "GET index" do
        @controller.current_ability.should_receive(:can?).with(:index, Child).and_return(false);
        get :index
        response.status.should == 403
      end

      it "GET search" do
        @controller.current_ability.should_receive(:can?).with(:index, Child).and_return(false);
        get :search
        response.status.should == 403
      end

      it "GET new" do
        @controller.current_ability.should_receive(:can?).with(:create, Child).and_return(false);
        get :new
        response.status.should == 403
      end

      it "POST create" do
        @controller.current_ability.should_receive(:can?).with(:create, Child).and_return(false);
        post :create
        response.status.should == 403
      end

    end

    describe 'member' do
      before :each do
        User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
        @child = Child.create('last_known_location' => "London", :short_id => 'short_id', :created_by => "uname")
        @child_arg = hash_including("_id" => @child.id)
      end

      it "GET show" do
        @controller.current_ability.should_receive(:can?).with(:read, @child_arg).and_return(false);
         get :show, :id => @child.id
         response.status.should == 403
      end

      it "PUT update" do
        @controller.current_ability.should_receive(:can?).with(:update, @child_arg).and_return(false);
        put :update, :id => @child.id
        response.status.should == 403
      end

      it "PUT edit_photo" do
        @controller.current_ability.should_receive(:can?).with(:update, @child_arg).and_return(false);
        put :edit_photo, :id => @child.id
        response.status.should == 403
      end

      it "PUT update_photo" do
        @controller.current_ability.should_receive(:can?).with(:update, @child_arg).and_return(false);
        put :update_photo, :id => @child.id
        response.status.should == 403
      end

      it "PUT select_primary_photo" do
        @controller.current_ability.should_receive(:can?).with(:update, @child_arg).and_return(false);
        put :select_primary_photo, :child_id => @child.id, :photo_id => 0
        response.status.should == 403
      end

      it "DELETE destroy" do
        @controller.current_ability.should_receive(:can?).with(:destroy, @child_arg).and_return(false);
        delete :destroy, :id => @child.id
        response.status.should == 403
      end
    end
  end

  describe "GET index" do

    shared_examples_for "viewing children by user with access to all data" do
      describe "when the signed in user has access all data" do
        before do
          fake_field_admin_login
          @options ||= {}
          @stubs ||= {}
        end

        it "should assign all childrens as @childrens" do
          page = @options.delete(:page)
          per_page = @options.delete(:per_page)
          children = [mock_child(@stubs)]
          @status ||= "all"

          children.stub!(:paginate).and_return(children)
  
          Child.should_receive(:fetch_paginated).with(@options, page, per_page).and_return([1, children])

          get :index, :status => @status
          assigns[:children].should == children
        end
      end
    end

    shared_examples_for "viewing children as a field worker" do
      describe "when the signed in user is a field worker" do
        before do
          @session = fake_field_worker_login
          @stubs ||= {}
          @options ||= {}
          @params ||= {}
        end

        it "should assign the children created by the user as @childrens" do
          children = [mock_child(@stubs)]
          page = @options.delete(:page)
          per_page = @options.delete(:per_page)
          @status ||= "all"
          children.stub!(:paginate).and_return(children)
          Child.should_receive(:fetch_paginated).with(@options, page, per_page).and_return([1, children])
          @params.merge!(:status => @status)
          get :index, @params
          assigns[:children].should == children
        end
      end
    end

    context "viewing all children" do
      before { @stubs = { :reunited? => false } }
      context "when status is passed for admin" do
        before { @status = "all"}
        before {@options = {:startkey=>["all"], :endkey=>["all", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name}}
        it_should_behave_like "viewing children by user with access to all data"
      end

      context "when status is passed for field worker" do
        before { @status = "all"}
        before {@options = {:startkey=>["all", "fakefieldworker"], :endkey=>["all","fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_created_at}}

        it_should_behave_like "viewing children as a field worker"
      end

      context "when status is not passed admin" do
        before {@options = {:startkey=>["all"], :endkey=>["all", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name}}
        it_should_behave_like "viewing children by user with access to all data"
      end

      context "when status is not passed field_worker" do
        before {@options = {:startkey=>["all", "fakefieldworker"], :endkey=>["all","fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_created_at}}
        it_should_behave_like "viewing children as a field worker"
      end

      context "when status is not passed field_worker and order is name" do
        before {@options = {:startkey=>["all", "fakefieldworker"], :endkey=>["all","fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_name}}
        before {@params = {:order_by => 'name'}}
        it_should_behave_like "viewing children as a field worker"
      end

      context "when status is not passed field_worker, order is created_at and page is 2" do
        before {@options = {:view_name=>:by_all_view_with_created_by_created_at, :startkey=>["all", "fakefieldworker", {}], :endkey=>["all", "fakefieldworker"], :descending=>true, :page=>2, :per_page=>20}}
        before {@params = {:order_by => 'created_at', :page => 2}}
        it_should_behave_like "viewing children as a field worker"
      end
    end

    context "viewing reunited children" do
      before do
        @status = "reunited"
        @stubs = {:reunited? => true}
      end
      context "admin" do
        before { @options = {:startkey=>["reunited"], :endkey=>["reunited", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name} }
        it_should_behave_like "viewing children by user with access to all data"
      end
      context "field worker" do
        before { @options = {:startkey=>["reunited", "fakefieldworker"], :endkey=>["reunited", "fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_created_at}}
        it_should_behave_like "viewing children as a field worker"
      end
    end

    context "viewing flagged children" do
      before { @status = "flagged" }
      context "admin" do
        before {@options = {:startkey=>["flagged"], :endkey=>["flagged", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name}}
        it_should_behave_like "viewing children by user with access to all data"
      end
      context "field_worker" do
        before {@options = {:startkey=>["flagged", "fakefieldworker"], :endkey=>["flagged", "fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_created_at}}
        it_should_behave_like "viewing children as a field worker"
      end
    end

    context "viewing active children" do
      before do
        @status = "active"
        @stubs = {:reunited? => false}
      end
      context "admin" do
        before {@options = {:startkey=>["active"], :endkey=>["active", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name}}
        it_should_behave_like "viewing children by user with access to all data"
      end
      context "field worker" do
        before {@options = {:startkey=>["active", "fakefieldworker"], :endkey=>["active", "fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_created_at}}
        it_should_behave_like "viewing children as a field worker"
      end
    end

    describe "export all to PDF/CSV/CPIMS/Photo Wall" do
      before do
        fake_field_admin_login
        @params ||= {}
        controller.stub! :paginated_collection => [], :render => true
      end
      it "should flash notice when exporting no records" do
        format = "cpims"
        @params.merge!(:format => format)
        get :index, @params
        flash[:notice].should == "No Records Available!"
      end
    end
  end

  describe "GET show" do
    it 'does not assign child name in page name' do
      child = build :child, :unique_identifier => "1234"
      controller.stub! :render
      get :show, :id => child.id
      assigns[:page_name].should == "View Child 1234"
    end

    it "assigns the requested child" do
      Child.stub!(:get).with("37").and_return(mock_child)
      get :show, :id => "37"
      assigns[:child].should equal(mock_child)
    end

    it 'should not fail if primary_photo_id is not present' do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", :created_by => "uname")
      child.create_unique_id
      Child.stub!(:get).with("37").and_return(child)
      Clock.stub!(:now).and_return(Time.parse("Jan 17 2010 14:05:32"))

      controller.stub! :render
      get(:show, :format => 'csv', :id => "37")
    end

    it "should set current photo key as blank instead of nil" do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", :created_by => "uname")
      child.create_unique_id
      Child.stub!(:get).with("37").and_return(child)
      assigns[child[:current_photo_key]] == ""
      get(:show, :format => 'json', :id => "37")
    end

    it "orders and assigns the forms" do
      Child.stub!(:get).with("37").and_return(mock_child)
      FormSection.should_receive(:enabled_by_order).and_return([:the_form_sections])
      get :show, :id => "37"
      assigns[:form_sections].should == [:the_form_sections]
    end

    it "should flash an error and go to listing page if the resource is not found" do
      Child.stub!(:get).with("invalid record").and_return(nil)
      get :show, :id=> "invalid record"
      flash[:error].should == "Child with the given id is not found"
      response.should redirect_to(:action => :index)
    end

    it "should include duplicate records in the response" do
      Child.stub!(:get).with("37").and_return(mock_child)
      duplicates = [Child.new(:name => "duplicated")]
      Child.should_receive(:duplicates_of).with("37").and_return(duplicates)
      get :show, :id => "37"
      assigns[:duplicates].should == duplicates
    end
  end

  describe "GET new" do
    it "assigns a new child as @child" do
      Child.stub!(:new).and_return(mock_child)
      get :new
      assigns[:child].should equal(mock_child)
    end

    it "orders and assigns the forms" do
      Child.stub!(:new).and_return(mock_child)
      FormSection.should_receive(:enabled_by_order).and_return([:the_form_sections])
      get :new
      assigns[:form_sections].should == [:the_form_sections]
    end
  end

  describe "GET edit" do
    it "assigns the requested child as @child" do
      Child.stub!(:get).with("37").and_return(mock_child)
      FormSection.should_receive(:enabled_by_order)
      get :edit, :id => "37"
      assigns[:child].should equal(mock_child)
    end

    it "orders and assigns the forms" do
      Child.stub!(:get).with("37").and_return(mock_child)
      FormSection.should_receive(:enabled_by_order).and_return([:the_form_sections])
      get :edit, :id => "37"
      assigns[:form_sections].should == [:the_form_sections]
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested child" do
      Child.should_receive(:get).with("37").and_return(mock_child)
      mock_child.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the children list" do
      Child.stub!(:get).and_return(mock_child(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(children_url)
    end
  end

  describe "PUT update" do
    it "should sanitize the parameters if the params are sent as string(params would be as a string hash when sent from mobile)" do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo, :created_by => "uname")
      child['histories'] = []
      child.save!

      Clock.stub!(:now).and_return(Time.parse("Jan 17 2010 14:05:32"))
      histories = "[{\"datetime\":\"2013-02-01 04:49:29UTC\",\"user_name\":\"rapidftr\",\"changes\":{\"photo_keys\":{\"added\":[\"photo-671592136-2013-02-01T101929\"],\"deleted\":null}},\"user_organisation\":\"N\\/A\"}]"
      put :update, :id => child.id,
           :child => {
               :last_known_location => "Manchester",
               :histories => histories
           }

     assigns[:child]['histories'].should == JSON.parse(histories)
    end

    it "should update child on a field and photo update" do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo, :created_by => "uname")

      Clock.stub!(:now).and_return(Time.parse("Jan 17 2010 14:05:32"))
      put :update, :id => child.id,
        :child => {
          :last_known_location => "Manchester",
          :photo => Rack::Test::UploadedFile.new(uploadable_photo_jeff) }

      assigns[:child]['last_known_location'].should == "Manchester"
      assigns[:child]['_attachments'].size.should == 2
      updated_photo_key = assigns[:child]['_attachments'].keys.select {|key| key =~ /photo.*?-2010-01-17T140532/}.first
      assigns[:child]['_attachments'][updated_photo_key]['data'].should_not be_blank
    end

    it "should update only non-photo fields when no photo update" do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo, :created_by => "uname")

      put :update, :id => child.id,
        :child => {
          :last_known_location => "Manchester",
          :age => '7'}

      assigns[:child]['last_known_location'].should == "Manchester"
      assigns[:child]['age'].should == "7"
      assigns[:child]['_attachments'].size.should == 1
    end

    it "should not update history on photo rotation" do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo_jeff, :created_by => "uname")
      Child.get(child.id)["histories"].size.should be 1

      expect{put(:update_photo, :id => child.id, :child => {:photo_orientation => "-180"})}.to_not change{Child.get(child.id)["histories"].size}
    end

    it "should allow a records ID to be specified to create a new record with a known id" do
      new_uuid = UUIDTools::UUID.random_create()
      put :update, :id => new_uuid.to_s,
        :child => {
            :id => new_uuid.to_s,
            :_id => new_uuid.to_s,
            :last_known_location => "London",
            :age => "7"
        }
      Child.get(new_uuid.to_s)[:unique_identifier].should_not be_nil
    end

    it "should update flag (cast as boolean) and flag message" do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo, :created_by => "uname")
      put :update, :id => child.id,
        :child => {
          :flag => true,
          :flag_message => "Possible Duplicate"
        }
      assigns[:child]['flag'].should be_true
      assigns[:child]['flag_message'].should == "Possible Duplicate"
    end

    it "should update history on flagging of record" do
      current_time_in_utc = Time.parse("20 Jan 2010 17:10:32UTC")
      current_time = Time.parse("20 Jan 2010 17:10:32")
      Clock.stub!(:now).and_return(current_time)
      current_time.stub!(:getutc).and_return current_time_in_utc
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo_jeff, :created_by => "uname")

      put :update, :id => child.id, :child => {:flag => true, :flag_message => "Test"}

      history = Child.get(child.id)["histories"].first
      history['changes'].should have_key('flag')
      history['datetime'].should == "2010-01-20 17:10:32UTC"
    end

    it "should update the last_updated_by_full_name field with the logged in user full name" do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.new_with_user_name(user, {:name => 'existing child'})
      Child.stub(:get).with("123").and_return(child)
      subject.should_receive('current_user_full_name').any_number_of_times.and_return('Bill Clinton')

      put :update, :id => 123, :child => {:flag => true, :flag_message => "Test"}

      child['last_updated_by_full_name'].should=='Bill Clinton'
    end

    it "should not set photo if photo is not passed" do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.new_with_user_name(user, {:name => 'some name'})
      params_child = {"name" => 'update'}
      controller.stub(:current_user_name).and_return("user_name")
      child.should_receive(:update_properties_with_user_name).with("user_name", "", nil, nil, params_child)
      Child.stub(:get).and_return(child)
      put :update, :id => '1', :child => params_child
      end


    it "should redirect to redirect_url if it is present in params" do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.new_with_user_name(user, {:name => 'some name'})
      params_child = {"name" => 'update'}
      controller.stub(:current_user_name).and_return("user_name")
      child.should_receive(:update_properties_with_user_name).with("user_name", "", nil, nil, params_child)
      Child.stub(:get).and_return(child)
      put :update, :id => '1', :child => params_child, :redirect_url => '/children'
      response.should redirect_to '/children'
    end

    it "should redirect to child page if redirect_url is not present in params" do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.new_with_user_name(user, {:name => 'some name'})

      params_child = {"name" => 'update'}
      controller.stub(:current_user_name).and_return("user_name")
      child.should_receive(:update_properties_with_user_name).with("user_name", "", nil, nil, params_child)
      Child.stub(:get).and_return(child)
      put :update, :id => '1', :child => params_child
      response.should redirect_to "/children/#{child.id}"
    end

  end

  describe "GET search" do
    it "should not render error by default" do
      get(:search, :format => 'html')
      assigns[:search].should be_nil
    end

    it "should render error if search is invalid" do
      get(:search, :format => 'html', :query => '2'*160)
      search = assigns[:search]
      search.errors.should_not be_empty
    end

    it "should stay in the page if search is invalid" do
      get(:search, :format => 'html', :query => '1'*160)
      response.should render_template("search")
    end

    it "performs a search using the parameters passed to it" do
      search = mock("search", :query => 'the child name', :valid? => true, :page => 1)
      Search.stub!(:new).and_return(search)

      fake_results = ["fake_child","fake_child"]
      fake_full_results =  [:fake_child,:fake_child, :fake_child, :fake_child]
      Child.should_receive(:search).with(search, 1).and_return([fake_results, fake_full_results])
      get(:search, :format => 'html', :query => 'the child name')
      assigns[:results].should == fake_results
    end

    describe "with no results" do
      before do
        get(:search, :query => 'blah')
      end

      it 'asks view to not show csv export link if there are no results' do
        assigns[:results].size.should == 0
      end

      it 'asks view to display a "No results found" message if there are no results' do
        assigns[:results].size.should == 0
      end

    end
  end

  describe "searching as field worker" do
    before :each do
      @session = fake_field_worker_login
    end
    it "should only list the children which the user has registered" do
      search = mock("search", :query => 'some_name', :valid? => true, :page => 1)
      Search.stub!(:new).and_return(search)

      fake_results = [:fake_child,:fake_child]
      fake_full_results =  [:fake_child,:fake_child, :fake_child, :fake_child]
      Child.should_receive(:search_by_created_user).with(search, @session.user_name, 1).and_return([fake_results, fake_full_results])

      get(:search, :query => 'some_name')
      assigns[:results].should == fake_results
    end
  end

  it 'should export children using #respond_to_export' do
    child1 = build :child
    child2 = build :child
    controller.stub! :paginated_collection => [ child1, child2 ], :render => true
    controller.should_receive(:YAY).and_return(true)

    controller.should_receive(:respond_to_export) { |format, children|
      format.mock { controller.send :YAY }
      children.should == [ child1, child2 ]
    }

    get :index, :format => :mock
  end

  it 'should export child using #respond_to_export' do
    child = build :child
    controller.stub! :render => true
    controller.should_receive(:YAY).and_return(true)

    controller.should_receive(:respond_to_export) { |format, children|
      format.mock { controller.send :YAY }
      children.should == [ child ]
    }

    get :show, :id => child.id, :format => :mock
  end

  describe '#respond_to_export' do
    before :each do
      @child1 = build :child
      @child2 = build :child
      controller.stub! :paginated_collection => [ @child1, @child2 ], :render => true
    end

    it "should handle full PDF" do
      Addons::PdfExportTask.any_instance.should_receive(:export).with([ @child1, @child2 ]).and_return('data')
      get :index, :format => :pdf
    end

    it "should handle Photowall PDF" do
      Addons::PhotowallExportTask.any_instance.should_receive(:export).with([ @child1, @child2 ]).and_return('data')
      get :index, :format => :photowall
    end

    it "should handle CSV" do
      Addons::CsvExportTask.any_instance.should_receive(:export).with([ @child1, @child2 ]).and_return('data')
      get :index, :format => :csv
    end

    it "should handle custom export addon" do
      mock_addon = double()
      mock_addon_class = double(:new => mock_addon, :id => "mock")
      RapidftrAddon::ExportTask.stub! :active => [ mock_addon_class ]
      controller.stub(:authorize!)
      mock_addon.should_receive(:export).with([ @child1, @child2 ]).and_return('data')
      get :index, :format => :mock
    end

    it "should encrypt result" do
      Addons::CsvExportTask.any_instance.should_receive(:export).with([ @child1, @child2 ]).and_return('data')
      controller.should_receive(:export_filename).with([ @child1, @child2 ], Addons::CsvExportTask).and_return("test_filename")
      controller.should_receive(:encrypt_exported_files).with('data', 'test_filename').and_return(true)
      get :index, :format => :csv
    end

    it "should create a log_entry when record is exported" do
      fake_login User.new(:user_name => 'fakeuser', :organisation => "STC", :role_ids => ["abcd"])
      @controller.stub(:authorize!)
      RapidftrAddonCpims::ExportTask.any_instance.should_receive(:export).with([ @child1, @child2 ]).and_return('data')

      LogEntry.should_receive(:create!).with :type => LogEntry::TYPE[:cpims], :user_name => "fakeuser", :organisation => "STC", :child_ids => [@child1.id, @child2.id]

      get :index, :format => :cpims
    end

    it "should generate filename based on child ID and addon ID when there is only one child" do
      @child1.stub! :short_id => 'test_short_id'
      controller.send(:export_filename, [ @child1 ], Addons::PhotowallExportTask).should == "test_short_id_photowall.zip"
    end

    it "should generate filename based on username and addon ID when there are multiple children" do
      controller.stub! :current_user_name => 'test_user'
      controller.send(:export_filename, [ @child1, @child2 ], Addons::PdfExportTask).should == "test_user_pdf.zip"
    end

    it "should handle CSV" do
      Addons::CsvExportTask.any_instance.should_receive(:export).with([ @child1, @child2 ]).and_return('data')
      get :index, :format => :csv
    end

  end

  describe "PUT select_primary_photo" do
    before :each do
      @child = stub_model(Child, :id => "id")
      @photo_key = "key"
      @child.stub(:primary_photo_id=)
      @child.stub(:save)
      Child.stub(:get).with("id").and_return @child
    end

    it "set the primary photo on the child and save" do
      @child.should_receive(:primary_photo_id=).with(@photo_key)
      @child.should_receive(:save)

      put :select_primary_photo, :child_id => @child.id, :photo_id => @photo_key
    end

    it "should return success" do
      put :select_primary_photo, :child_id => @child.id, :photo_id => @photo_key

      response.should be_success
    end

    context "when setting new primary photo id errors" do
      before :each do
        @child.stub(:primary_photo_id=).and_raise("error")
      end

      it "should return error" do
        put :select_primary_photo, :child_id => @child.id, :photo_id => @photo_key

        response.should be_error
      end
    end
  end

  describe "PUT create" do
    it "should add the full user_name of the user who created the Child record" do
      Child.should_receive('new_with_user_name').and_return(child = Child.new)
      controller.should_receive('current_user_full_name').and_return('Bill Clinton')
      put :create, :child => {:name => 'Test Child' }
      child['created_by_full_name'].should=='Bill Clinton'
    end
  end

  describe "sync_unverified" do
    before :each do
      @user = build :user, :verified => false, :role_ids => []
      fake_login @user
    end

    it "should mark all children created as verified/unverifid based on the user" do
      @user.verified = true
      Child.should_receive(:new_with_user_name).with(@user, {"name" => "timmy", "verified" => @user.verified?}).and_return(child = Child.new)
      child.should_receive(:save).and_return true

      post :sync_unverified, {:child => {:name => "timmy"}, :format => :json}

      @user.verified = true
    end

    it "should set the created_by name to that of the user matching the params" do
      Child.should_receive(:new_with_user_name).and_return(child = Child.new)
      child.should_receive(:save).and_return true

      post :sync_unverified, {:child => {:name => "timmy"}, :format => :json}

      child['created_by_full_name'].should eq @user.full_name
    end

    it "should update the child instead of creating new child everytime" do
      Child.should_receive(:by_short_id).with(:key => '1234567').and_return(child = Child.new)
      controller.should_receive(:update_child_from).and_return(child)
      child.should_receive(:save).and_return true

      post :sync_unverified, {:child => {:name => "timmy", :unique_identifier => '12345671234567'}, :format => :json}

      child['created_by_full_name'].should eq @user.full_name
    end
  end

  describe "POST create" do
    it "should update the child record instead of creating if record already exists" do
      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.new_with_user_name(user, {:name => 'old name'})
      child.save
      child_fake_admin_login
      controller.stub(:authorize!)
      post :create, :child => {:unique_identifier => child.unique_identifier, :name => 'new name'}
      updated_child = Child.by_short_id(:key => child.short_id)
      updated_child.size.should == 1
      updated_child.first.name.should == 'new name'
    end
  end

end
