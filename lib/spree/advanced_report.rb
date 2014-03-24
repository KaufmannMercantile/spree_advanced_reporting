module Spree
  class AdvancedReport
    include Ruport
    include Spree::Admin::AdvancedReportHelper
    attr_accessor :orders, :product_text, :date_text, :taxon_text, :ruportdata, :search,
                      :data, :params, :taxon, :product, :product_in_taxon, :unfiltered_params

    def name
      I18n.t("adv_report.base.name")
    end

    def description
      I18n.t("adv_report.base.description")
    end

    def initialize(params)
      self.params ||= params
      self.data = {}
      self.ruportdata = {}
      self.unfiltered_params = params[:search].blank? ? {} : params[:search].clone

      params[:search] ||= {}
      params[:advanced_reporting] ||= {}

      if params[:search][:completed_at_gt].blank?
        self.unfiltered_params[:completed_at_gt] = datepicker_field_value((SpreeAdvancedReporting.default_min_date).beginning_of_day)
        params[:search][:completed_at_gt] = (SpreeAdvancedReporting.default_min_date).beginning_of_day #Order.minimum(:completed_at).beginning_of_day
      else
        params[:search][:completed_at_gt] = Time.zone.parse(params[:search][:completed_at_gt]).beginning_of_day rescue ""
      end
      if params[:search][:completed_at_lt].blank?
        self.unfiltered_params[:completed_at_lt] = datepicker_field_value(Time.now.end_of_day)
        params[:search][:completed_at_lt] = Time.now.end_of_day #Order.maximum(:completed_at).end_of_day
      else
        params[:search][:completed_at_lt] = Time.zone.parse(params[:search][:completed_at_lt]).end_of_day rescue ""
      end

      params[:search][:completed_at_not_null] = true
      params[:search][:state_not_eq] = 'canceled'

      search = Order.search(params[:search])
      # self.orders = search.state_does_not_equal('canceled')
      self.orders = search.result

      self.product_in_taxon = true
      if params[:advanced_reporting]
        if params[:advanced_reporting][:taxon_id] && params[:advanced_reporting][:taxon_id] != ''
          self.taxon = Taxon.find(params[:advanced_reporting][:taxon_id])
        end
        if params[:advanced_reporting][:product_id] && params[:advanced_reporting][:product_id] != ''
          self.product = Product.find(params[:advanced_reporting][:product_id])
        end
      end
      if self.taxon && self.product && !self.product.taxons.include?(self.taxon)
        self.product_in_taxon = false
      end

      if self.product
        self.product_text = "Product: #{self.product.name}<br />"
      end
      if self.taxon
        self.taxon_text = "Taxon: #{self.taxon.name}<br />"
      end

      # Above searchlogic date settings
      self.date_text = "#{I18n.t(:date_range)}<br />"
      if self.unfiltered_params
        if self.unfiltered_params[:completed_at_gt] != '' && self.unfiltered_params[:completed_at_lt] != ''
          self.date_text += "#{I18n.t(:from)} #{self.unfiltered_params[:completed_at_gt]} #{I18n.t(:to)} #{self.unfiltered_params[:completed_at_lt]}"
        elsif self.unfiltered_params[:completed_at_gt] != ''
          self.date_text += " #{I18n.t(:after)} #{self.unfiltered_params[:completed_at_gt]}"
        elsif self.unfiltered_params[:completed_at_lt] != ''
          self.date_text += " #{I18n.t(:before)} #{self.unfiltered_params[:completed_at_lt]}"
        else
          self.date_text += " #{I18n.t(:all)}"
        end
      else
        self.date_text += " #{I18n.t(:all)}"
      end
    end

    def download_url(base, format, report_type = nil)
      elements = []
      params[:advanced_reporting] ||= {}
      params[:advanced_reporting]["report_type"] = report_type if report_type
      if params
        [:search, :advanced_reporting].each do |type|
          if params[type]
            params[type].each { |k, v| elements << "#{type}[#{k}]=#{v}" }
          end
        end
      end
      base.gsub!(/^\/\//,'/')
      base + '.' + format + '?' + elements.join('&')
    end

    def revenue(order)
      rev = order.line_items.inject(0) { |a, b| a += b.quantity * (b.price / (1 + (b.andand.tax_category.andand.tax_rates.andand.first.andand.amount || b.andand.variant.andand.product.andand.tax_category.andand.tax_rates.andand.amount || 0 ))) }
      if !self.product.nil? && product_in_taxon
        rev = order.line_items.select { |li| li.product == self.product }.inject(0) { |a, b| a += b.quantity * (b.price / (1 + (b.andand.tax_category.andand.tax_rates.andand.first.andand.amount || b.andand.variant.andand.product.andand.tax_category.andand.tax_rates.andand.amount || 0 ))) }
      elsif !self.taxon.nil?
        rev = order.line_items.select { |li| li.product && li.product.taxons.include?(self.taxon) }.inject(0) { |a, b| a += b.quantity * (b.price / (1 + (b.andand.tax_category.andand.tax_rates.andand.first.andand.amount || b.andand.variant.andand.product.andand.tax_category.andand.tax_rates.andand.amount || 0 ))) }
      end
      self.product_in_taxon ? rev : 0
    end

    def tax(order)
      tax = {}
      Spree::TaxCategory.all.each do |c|
        tax["#{c.name}"] ||= 0
        tax["#{c.name}"] += order.line_items.select{|li| li.tax_category == c}.inject(0) { |tax, li| li.quantity * (li.price - (li.price / (1+ c.tax_rates.first.amount)))}

        tax["total_#{c.name}"] ||= 0
        tax["total_#{c.name}"] += order.line_items.select{|li| li.tax_category == c}.inject(0) { |tax, li| li.quantity * li.price}
      end

      if !self.product.nil? && product_in_taxon
        Spree::TaxCategory.all.each do |c|
          tax["#{c.name}"] ||= 0
          tax["#{c.name}"] += order.line_items.select { |li| li.product == self.product }.select{|li| li.tax_category == c}.inject(0) { |tax, li| li.quantity * (li.price - (li.price / (1+ c.tax_rates.first.amount)))}

          tax["total_#{c.name}"] ||= 0
          tax["total_#{c.name}"] += order.line_items.select { |li| li.product == self.product }.select{|li| li.tax_category == c}.inject(0) { |tax, li| li.quantity * li.price}
        end
      elsif !self.taxon.nil?
        Spree::TaxCategory.all.each do |c|
          tax["#{c.name}"] ||= 0
          tax["#{c.name}"] += order.line_items.select { |li| li.product && li.product.taxons.include?(self.taxon) }.select { |li| li.product == self.product }.select{|li| li.tax_category == c}.inject(0) { |tax, li| li.quantity * (li.price - (li.price / (1+ c.tax_rates.first.amount)))}

          tax["total_#{c.name}"] ||= 0
          tax["total_#{c.name}"] += order.line_items.select { |li| li.product && li.product.taxons.include?(self.taxon) }.select { |li| li.product == self.product }.select{|li| li.tax_category == c}.inject(0) { |tax, li| li.quantity * li.price}
        end
      end
      self.product_in_taxon ? tax : {}
    end

    def profit(order)
      profit = order.line_items.inject(0) { |profit, li| profit + ((li.price / (1 + (li.andand.tax_category.andand.tax_rates.andand.first.andand.amount || li.andand.variant.andand.product.andand.tax_category.andand.tax_rates.andand.amount || 0))) - (li.cost_price || li.variant.cost_price || li.variant.product.master.cost_price.to_f))*li.quantity }
      if !self.product.nil? && product_in_taxon
        profit = order.line_items.select { |li| li.product == self.product }.inject(0) { |profit, li| profit + ((li.price / (1 + (li.andand.tax_category.andand.tax_rates.andand.first.andand.amount || li.andand.variant.andand.product.andand.tax_category.andand.tax_rates.andand.amount || 0 ))) - (li.cost_price || li.variant.cost_price || li.variant.product.master.cost_price.to_f))*li.quantity }
      elsif !self.taxon.nil?
        profit = order.line_items.select { |li| li.product && li.product.taxons.include?(self.taxon) }.inject(0) { |profit, li| profit + ((li.price / (1 + (li.andand.tax_category.andand.tax_rates.andand.first.andand.amount || li.andand.variant.andand.product.andand.tax_category.andand.tax_rates.andand.amount || 0 ))) - (li.cost_price || li.variant.cost_price || li.variant.product.master.cost_price.to_f))*li.quantity }
      end
      self.product_in_taxon ? profit : 0
    end

    def units(order)
      units = order.line_items.sum(:quantity)
      if !self.product.nil? && product_in_taxon
        units = order.line_items.select { |li| li.product == self.product }.inject(0) { |a, b| a += b.quantity }
      elsif !self.taxon.nil?
        units = order.line_items.select { |li| li.product && li.product.taxons.include?(self.taxon) }.inject(0) { |a, b| a += b.quantity }
      end
      self.product_in_taxon ? units : 0
    end

    def order_count(order)
      self.product_in_taxon ? 1 : 0
    end

    def multi_store_order_count(order)
      order.line_items.detect{|li| li.variant.product.stores.first != order.store}.blank? ? 0 : 1
    end
  end
end
