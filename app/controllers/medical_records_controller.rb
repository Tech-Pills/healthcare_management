class MedicalRecordsController < ApplicationController
  before_action :set_medical_record, only: %i[ show edit update destroy purge_attachment ]

  # GET /medical_records or /medical_records.json
  def index
    @medical_records = MedicalRecord.all
  end

  # GET /medical_records/1 or /medical_records/1.json
  def show
  end

  # GET /medical_records/new
  def new
    @medical_record = MedicalRecord.new
    @medical_record.recorded_at = Time.current
  end

  # GET /medical_records/1/edit
  def edit
  end

  # POST /medical_records or /medical_records.json
  def create
    @medical_record = MedicalRecord.new(medical_record_params)

    respond_to do |format|
      if @medical_record.save
        format.html { redirect_to @medical_record, notice: "Medical record was successfully created." }
        format.json { render :show, status: :created, location: @medical_record }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @medical_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /medical_records/1 or /medical_records/1.json
  def update
    respond_to do |format|
      if @medical_record.update(medical_record_params)
        format.html { redirect_to @medical_record, notice: "Medical record was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @medical_record }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @medical_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /medical_records/1 or /medical_records/1.json
  def destroy
    @medical_record.destroy!

    respond_to do |format|
      format.html { redirect_to medical_records_path, notice: "Medical record was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # DELETE /medical_records/1/purge_attachment
  def purge_attachment
    attachment_name = params[:attachment]

    if attachment_name == "x_ray_image" && @medical_record.x_ray_image.attached?
      @medical_record.x_ray_image.purge_later
      notice = "X-ray image is being removed."
    elsif attachment_name == "lab_result"
      blob_id = params[:blob_id]
      attachment = @medical_record.lab_results.find { |lr| lr.blob.id == blob_id.to_i }
      attachment.purge_later if attachment
      notice = "Lab result is being removed."
    end

    respond_to do |format|
      format.html { redirect_to @medical_record, notice: notice, status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_medical_record
      @medical_record = MedicalRecord.find(params.expect(:id))
    end

    def medical_record_params
      params.expect(medical_record: [
        :patient_id, :appointment_id, :recorded_at,
        :weight, :height, :heart_rate, :temperature,
        :blood_pressure_systolic, :blood_pressure_diastolic,
        :diagnosis, :medications, :allergies, :notes,
        :x_ray_image, lab_results: []
      ])
    end
end
