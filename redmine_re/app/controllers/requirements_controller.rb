class RequirementsController < RedmineReController
  unloadable
  menu_item :re

  def index
    @html_tree = create_tree
    @project_artifact = ReArtifactProperties.find_by_artifact_type_and_project_id("Project", @project.id)
    
    if @project_artifact.nil?
      redirect_to :action => "setup", :project_id => @project.id
    end
  end

  def setup
    @project = Project.find(params[:project_id])
    
    @project_artifact = nil
    @project_artifact = ReArtifactProperties.find_by_artifact_type_and_project_id("Project", @project.id)
    if @project_artifact.nil?
      @project_artifact = ReArtifactProperties.new 
      @project_artifact.project = @project
      @project_artifact.created_by = User.first # is there a better solution?
      @project_artifact.updated_by = User.first # actually this is not editable anyway
      @project_artifact.artifact_type = "Project"
      @project_artifact.artifact_id = @project.id
      @project_artifact.description = @project.description
      @project_artifact.priority = 50
      @project_artifact.name = @project.name
      @project_artifact.save
    end
  end

  def delegate_tree_drop
    # The following method is called via if somebody drops an artifact on the tree.
    # It transmits the drops done in the tree to the database in order to last
    # longer than the next refresh of the browser.
    new_parent_id = params[:new_parent_id]
    left_artifact_id = params[:left_artifact_id]
    moved_artifact_id = params[:id]

    moved_artifact = ReArtifactProperties.find(moved_artifact_id)
    
		new_parent = nil
		begin
	 	  new_parent = ReArtifactProperties.find(new_parent_id) if not new_parent_id.empty?
		rescue ActiveRecord::RecordNotFound
      new_parent = ReArtifactProperties.find_by_project_id_and_artifact_type(moved_artifact.project_id, "Project")
		end
    session[:expanded_nodes] << new_parent.id
		
		left_artifact = nil
    left_artifact = ReArtifactProperties.find(left_artifact_id) if not left_artifact_id.empty?

    position = 1
    position = (left_artifact.position + 1) unless left_artifact.nil? || left_artifact.position.nil?
    
    moved_artifact.set_parent(new_parent, position)
   
    #render :nothing => true
    debugtext = 'insert position: ' + position.to_s + ' - left '
    debugtext += left_artifact.position.to_s + ' ' + left_artifact.name.to_s unless left_artifact.nil? || left_artifact.position.nil?
    
    render :text => debugtext
  end

  # first tries to enable a contextmenu in artifact tree
  def context_menu
    @artifact =  ReArtifactProperties.find_by_id(params[:id])

    render :text => "Could not find artifact.", :status => 500 unless @artifact

    @subartifact_controller = @artifact.artifact_type.to_s.underscore
    @back = params[:back_url] || request.env['HTTP_REFERER']

    render :layout => false
  end

  def treestate
    # this method saves the state of a node
    # i.e. when you open or close a node in the tree
    # this state will be saved in the session
    # whenever you render the tree the rendering function will ask the
    # session for the nodes that are "opened" to render the children
    node_id = params[:id].to_i
    ret = ''
    if params[:open] == 'true'
      session[:expanded_nodes] << node_id
      re_artifact_properties =  ReArtifactProperties.find(node_id)
      ret = render_children_to_html_tree(re_artifact_properties, 1)
    else
      session[:expanded_nodes].delete(node_id)
    end
    render :inline => ret
  end  
  
end