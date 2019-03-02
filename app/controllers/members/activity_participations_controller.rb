class Members::ActivityParticipationsController < Members::BaseController
  # GET /activity_participations
  def index
  end

  # POST /activity_participations
  def create
    @activity_participation = current_member.activity_participations.new(protected_params)
    @activity_participation.session_id = session_id

    respond_to do |format|
      if @activity_participation.save
        flash[:notice] = t('.flash.notice')
        format.html { redirect_to members_activity_participations_path }
      else
        format.html { render :index }
      end
    end
  end

  # DELETE /activity_participations/:id
  def destroy
    participation = current_member.activity_participations.find(params[:id])
    participation.destroy if participation.destroyable?

    redirect_to members_activity_participations_path
  end

  private

  def protected_params
    params
      .require(:activity_participation)
      .permit(%i[activity_id participants_count carpooling carpooling_phone carpooling_city])
  end
end
