
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  
  "graphql_public": {
          Tables: {
            [_ in never]: never
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "graphql":
{ Args: { "extensions"?: Json,"operationName"?: string,"query"?: string,"variables"?: Json }; Returns: Json
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        },"public": {
          Tables: {
            "appointment_items": {
                  Row: {
                    "appointment_id": string,"buffer_after_minutes": number,"buffer_before_minutes": number,"busy_range": unknown,"created_at": string,"created_by": string | null,"effective_end": string,"effective_start": string,"id": string,"staff_id": string | null,"status_active": boolean,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "appointment_id": string,"buffer_after_minutes"?: number,"buffer_before_minutes"?: number,"busy_range"?: unknown,"created_at"?: string,"created_by"?: string | null,"effective_end": string,"effective_start": string,"id"?: string,"staff_id"?: string | null,"status_active"?: boolean,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "appointment_id"?: string,"buffer_after_minutes"?: number,"buffer_before_minutes"?: number,"busy_range"?: unknown,"created_at"?: string,"created_by"?: string | null,"effective_end"?: string,"effective_start"?: string,"id"?: string,"staff_id"?: string | null,"status_active"?: boolean,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "appointment_items_appointment_id_tenant_id_fkey"
      columns: ["appointment_id","tenant_id"]
isOneToOne: false
      referencedRelation: "appointments"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "appointment_items_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "appointment_items_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"appointments": {
                  Row: {
                    "branch_id": string,"created_at": string,"created_by": string | null,"id": string,"notes": string | null,"scheduled_end": string,"scheduled_start": string,"status": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"notes"?: string | null,"scheduled_end": string,"scheduled_start": string,"status"?: string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"notes"?: string | null,"scheduled_end"?: string,"scheduled_start"?: string,"status"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "appointments_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "appointments_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"audit_log": {
                  Row: {
                    "action": string,"actor_id": string | null,"branch_id": string | null,"changed_fields": NonNullable<Json>,"created_at": string,"entity_id": string | null,"entity_type": string,"id": number,"tenant_id": string
                  }
                  Insert: {
                    "action": string,"actor_id"?: string | null,"branch_id"?: string | null,"changed_fields"?: NonNullable<Json>,"created_at"?: string,"entity_id"?: string | null,"entity_type": string,"id"?: never,"tenant_id": string
                  }
                  Update: {
                    "action"?: string,"actor_id"?: string | null,"branch_id"?: string | null,"changed_fields"?: NonNullable<Json>,"created_at"?: string,"entity_id"?: string | null,"entity_type"?: string,"id"?: never,"tenant_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "audit_log_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "audit_log_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"blocked_time_types": {
                  Row: {
                    "color": string,"created_at": string,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string | null,"sort_order": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "color"?: string,"created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "color"?: string,"created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "blocked_time_types_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"blocked_times": {
                  Row: {
                    "all_branches": boolean,"blocked_range": unknown,"blocked_time_type_id": string,"branch_id": string | null,"created_at": string,"created_by": string | null,"ends_at": string,"id": string,"notes": string | null,"staff_id": string,"starts_at": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "all_branches"?: boolean,"blocked_range"?: never,"blocked_time_type_id": string,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"ends_at": string,"id"?: string,"notes"?: string | null,"staff_id": string,"starts_at": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "all_branches"?: boolean,"blocked_range"?: never,"blocked_time_type_id"?: string,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"ends_at"?: string,"id"?: string,"notes"?: string | null,"staff_id"?: string,"starts_at"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "blocked_times_blocked_time_type_id_tenant_id_fkey"
      columns: ["blocked_time_type_id","tenant_id"]
isOneToOne: false
      referencedRelation: "blocked_time_types"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "blocked_times_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "blocked_times_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "blocked_times_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"branch_opening_hours": {
                  Row: {
                    "branch_id": string,"closes_at": string,"created_at": string,"day_of_week": number,"id": string,"is_closed": boolean,"opens_at": string,"seq": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "branch_id": string,"closes_at": string,"created_at"?: string,"day_of_week": number,"id"?: string,"is_closed"?: boolean,"opens_at": string,"seq"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "branch_id"?: string,"closes_at"?: string,"created_at"?: string,"day_of_week"?: number,"id"?: string,"is_closed"?: boolean,"opens_at"?: string,"seq"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "branch_opening_hours_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    }
                  ]
                },"branches": {
                  Row: {
                    "address": string | null,"created_at": string,"enabled_payment_methods": (string)[],"first_day_of_week": number,"id": string,"invoice_prefix": string,"is_active": boolean,"name_ar": string | null,"name_en": string,"phone": string | null,"receipt_footer_ar": string | null,"receipt_footer_en": string | null,"receipt_header_ar": string | null,"receipt_header_en": string | null,"slot_step_minutes": number,"tenant_id": string,"time_format": number,"timezone": string,"tip_presets_percent": (number)[],"tips_enabled": boolean,"updated_at": string
                  }
                  Insert: {
                    "address"?: string | null,"created_at"?: string,"enabled_payment_methods"?: (string)[],"first_day_of_week"?: number,"id"?: string,"invoice_prefix"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en": string,"phone"?: string | null,"receipt_footer_ar"?: string | null,"receipt_footer_en"?: string | null,"receipt_header_ar"?: string | null,"receipt_header_en"?: string | null,"slot_step_minutes"?: number,"tenant_id": string,"time_format"?: number,"timezone"?: string,"tip_presets_percent"?: (number)[],"tips_enabled"?: boolean,"updated_at"?: string
                  }
                  Update: {
                    "address"?: string | null,"created_at"?: string,"enabled_payment_methods"?: (string)[],"first_day_of_week"?: number,"id"?: string,"invoice_prefix"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string,"phone"?: string | null,"receipt_footer_ar"?: string | null,"receipt_footer_en"?: string | null,"receipt_header_ar"?: string | null,"receipt_header_en"?: string | null,"slot_step_minutes"?: number,"tenant_id"?: string,"time_format"?: number,"timezone"?: string,"tip_presets_percent"?: (number)[],"tips_enabled"?: boolean,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "branches_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"cancellation_reasons": {
                  Row: {
                    "created_at": string,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string | null,"sort_order": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "cancellation_reasons_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"closed_periods": {
                  Row: {
                    "branch_id": string,"created_at": string,"ends_on": string,"id": string,"name_ar": string | null,"name_en": string | null,"starts_on": string,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"ends_on": string,"id"?: string,"name_ar"?: string | null,"name_en"?: string | null,"starts_on": string,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"ends_on"?: string,"id"?: string,"name_ar"?: string | null,"name_en"?: string | null,"starts_on"?: string,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "closed_periods_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    }
                  ]
                },"currencies": {
                  Row: {
                    "code": string,"is_active": boolean,"minor_exponent": number,"name_ar": string,"name_en": string,"symbol": string | null
                  }
                  Insert: {
                    "code": string,"is_active"?: boolean,"minor_exponent": number,"name_ar": string,"name_en": string,"symbol"?: string | null
                  }
                  Update: {
                    "code"?: string,"is_active"?: boolean,"minor_exponent"?: number,"name_ar"?: string,"name_en"?: string,"symbol"?: string | null
                  }
                  Relationships: [
                    
                  ]
                },"idempotency_keys": {
                  Row: {
                    "created_at": string,"function_name": string,"id": string,"key": string,"request_hash": string,"response_body": Json | null,"response_status": number | null,"status": string,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "created_at"?: string,"function_name": string,"id"?: string,"key": string,"request_hash": string,"response_body"?: Json | null,"response_status"?: number | null,"status"?: string,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "created_at"?: string,"function_name"?: string,"id"?: string,"key"?: string,"request_hash"?: string,"response_body"?: Json | null,"response_status"?: number | null,"status"?: string,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "idempotency_keys_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"invoice_counters": {
                  Row: {
                    "branch_id": string,"created_at": string,"id": string,"kind": string,"next_number": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"id"?: string,"kind": string,"next_number"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"id"?: string,"kind"?: string,"next_number"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "invoice_counters_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    }
                  ]
                },"memberships": {
                  Row: {
                    "all_branches": boolean,"branch_id": string | null,"created_at": string,"created_by": string | null,"id": string,"is_active": boolean,"role": string,"tenant_id": string,"updated_at": string,"updated_by": string | null,"user_id": string
                  }
                  Insert: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"is_active"?: boolean,"role": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null,"user_id": string
                  }
                  Update: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"is_active"?: boolean,"role"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "memberships_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "memberships_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"plan_features": {
                  Row: {
                    "created_at": string,"feature": string,"plan_code": string
                  }
                  Insert: {
                    "created_at"?: string,"feature": string,"plan_code": string
                  }
                  Update: {
                    "created_at"?: string,"feature"?: string,"plan_code"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "plan_features_plan_code_fkey"
      columns: ["plan_code"]
isOneToOne: false
      referencedRelation: "plans"
      referencedColumns: ["code"]
    }
                  ]
                },"plans": {
                  Row: {
                    "code": string,"created_at": string,"is_active": boolean,"name_ar": string,"name_en": string,"updated_at": string
                  }
                  Insert: {
                    "code": string,"created_at"?: string,"is_active"?: boolean,"name_ar": string,"name_en": string,"updated_at"?: string
                  }
                  Update: {
                    "code"?: string,"created_at"?: string,"is_active"?: boolean,"name_ar"?: string,"name_en"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    
                  ]
                },"profiles": {
                  Row: {
                    "avatar_url": string | null,"created_at": string,"full_name": string,"id": string,"locale": string,"phone": string | null,"updated_at": string
                  }
                  Insert: {
                    "avatar_url"?: string | null,"created_at"?: string,"full_name": string,"id": string,"locale"?: string,"phone"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "avatar_url"?: string | null,"created_at"?: string,"full_name"?: string,"id"?: string,"locale"?: string,"phone"?: string | null,"updated_at"?: string
                  }
                  Relationships: [
                    
                  ]
                },"service_branch_overrides": {
                  Row: {
                    "branch_id": string,"buffer_after_minutes": number | null,"buffer_before_minutes": number | null,"created_at": string,"created_by": string | null,"duration_minutes": number | null,"id": string,"is_enabled": boolean,"price_minor": number | null,"service_id": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "branch_id": string,"buffer_after_minutes"?: number | null,"buffer_before_minutes"?: number | null,"created_at"?: string,"created_by"?: string | null,"duration_minutes"?: number | null,"id"?: string,"is_enabled"?: boolean,"price_minor"?: number | null,"service_id": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "branch_id"?: string,"buffer_after_minutes"?: number | null,"buffer_before_minutes"?: number | null,"created_at"?: string,"created_by"?: string | null,"duration_minutes"?: number | null,"id"?: string,"is_enabled"?: boolean,"price_minor"?: number | null,"service_id"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "service_branch_overrides_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_branch_overrides_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "service_effective_values"
      referencedColumns: ["service_id","tenant_id"]
    },{
      foreignKeyName: "service_branch_overrides_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "services"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_branch_overrides_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"service_categories": {
                  Row: {
                    "created_at": string,"created_by": string | null,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string | null,"sort_order": number,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "created_at"?: string,"created_by"?: string | null,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "created_at"?: string,"created_by"?: string | null,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "service_categories_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"service_staff": {
                  Row: {
                    "branch_id": string,"created_at": string,"created_by": string | null,"id": string,"service_id": string,"staff_id": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"service_id": string,"staff_id": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"service_id"?: string,"staff_id"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "service_staff_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "service_effective_values"
      referencedColumns: ["service_id","tenant_id"]
    },{
      foreignKeyName: "service_staff_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "services"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_staff_id_branch_id_fkey"
      columns: ["staff_id","branch_id"]
isOneToOne: false
      referencedRelation: "staff_branch_assignments"
      referencedColumns: ["staff_id","branch_id"]
    },{
      foreignKeyName: "service_staff_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"services": {
                  Row: {
                    "buffer_after_minutes": number,"buffer_before_minutes": number,"category_id": string,"created_at": string,"created_by": string | null,"description_ar": string | null,"description_en": string | null,"duration_minutes": number,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string | null,"price_minor": number,"search_text": string | null,"sort_order": number,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "buffer_after_minutes"?: number,"buffer_before_minutes"?: number,"category_id": string,"created_at"?: string,"created_by"?: string | null,"description_ar"?: string | null,"description_en"?: string | null,"duration_minutes": number,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"price_minor": number,"search_text"?: never,"sort_order"?: number,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "buffer_after_minutes"?: number,"buffer_before_minutes"?: number,"category_id"?: string,"created_at"?: string,"created_by"?: string | null,"description_ar"?: string | null,"description_en"?: string | null,"duration_minutes"?: number,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"price_minor"?: number,"search_text"?: never,"sort_order"?: number,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "services_category_id_tenant_id_fkey"
      columns: ["category_id","tenant_id"]
isOneToOne: false
      referencedRelation: "service_categories"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "services_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"settings": {
                  Row: {
                    "all_branches": boolean,"branch_id": string | null,"created_at": string,"created_by": string | null,"id": string,"key": string,"tenant_id": string,"updated_at": string,"updated_by": string | null,"value": NonNullable<Json>
                  }
                  Insert: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"key": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null,"value": NonNullable<Json>
                  }
                  Update: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"key"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null,"value"?: NonNullable<Json>
                  }
                  Relationships: [
                    {
      foreignKeyName: "settings_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "settings_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"shifts": {
                  Row: {
                    "branch_id": string,"created_at": string,"created_by": string | null,"ends_at": string,"id": string,"staff_id": string,"starts_at": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"created_by"?: string | null,"ends_at": string,"id"?: string,"staff_id": string,"starts_at": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"created_by"?: string | null,"ends_at"?: string,"id"?: string,"staff_id"?: string,"starts_at"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "shifts_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "shifts_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "shifts_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"staff_branch_assignments": {
                  Row: {
                    "branch_id": string,"created_at": string,"created_by": string | null,"id": string,"is_bookable": boolean,"is_default": boolean,"staff_id": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"is_bookable"?: boolean,"is_default"?: boolean,"staff_id": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"is_bookable"?: boolean,"is_default"?: boolean,"staff_id"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "staff_branch_assignments_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "staff_branch_assignments_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "staff_branch_assignments_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"staff_members": {
                  Row: {
                    "created_at": string,"created_by": string | null,"email": string | null,"full_name_ar": string | null,"full_name_en": string | null,"id": string,"is_active": boolean,"is_bookable": boolean,"job_title_ar": string | null,"job_title_en": string | null,"phone": string | null,"search_text": string | null,"tenant_id": string,"updated_at": string,"updated_by": string | null,"user_id": string | null
                  }
                  Insert: {
                    "created_at"?: string,"created_by"?: string | null,"email"?: string | null,"full_name_ar"?: string | null,"full_name_en"?: string | null,"id"?: string,"is_active"?: boolean,"is_bookable"?: boolean,"job_title_ar"?: string | null,"job_title_en"?: string | null,"phone"?: string | null,"search_text"?: never,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null,"user_id"?: string | null
                  }
                  Update: {
                    "created_at"?: string,"created_by"?: string | null,"email"?: string | null,"full_name_ar"?: string | null,"full_name_en"?: string | null,"id"?: string,"is_active"?: boolean,"is_bookable"?: boolean,"job_title_ar"?: string | null,"job_title_en"?: string | null,"phone"?: string | null,"search_text"?: never,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null,"user_id"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "staff_members_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"tenants": {
                  Row: {
                    "created_at": string,"currency_code": string,"default_locale": string,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string,"plan": string,"slug": string,"updated_at": string
                  }
                  Insert: {
                    "created_at"?: string,"currency_code"?: string,"default_locale"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en": string,"plan"?: string,"slug": string,"updated_at"?: string
                  }
                  Update: {
                    "created_at"?: string,"currency_code"?: string,"default_locale"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string,"plan"?: string,"slug"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "tenants_currency_code_fkey"
      columns: ["currency_code"]
isOneToOne: false
      referencedRelation: "currencies"
      referencedColumns: ["code"]
    },{
      foreignKeyName: "tenants_plan_fkey"
      columns: ["plan"]
isOneToOne: false
      referencedRelation: "plans"
      referencedColumns: ["code"]
    }
                  ]
                }
          }
          Views: {
            "service_effective_values": {
                  Row: {
                    "branch_id": string | null,"buffer_after_minutes": number | null,"buffer_before_minutes": number | null,"category_id": string | null,"duration_minutes": number | null,"has_override": boolean | null,"is_enabled": boolean | null,"name_ar": string | null,"name_en": string | null,"price_minor": number | null,"service_id": string | null,"tenant_id": string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "services_category_id_tenant_id_fkey"
      columns: ["category_id","tenant_id"]
isOneToOne: false
      referencedRelation: "service_categories"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "services_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"service_eligible_staff": {
                  Row: {
                    "branch_id": string | null,"full_name_ar": string | null,"full_name_en": string | null,"service_id": string | null,"staff_id": string | null,"tenant_id": string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "service_staff_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "service_effective_values"
      referencedColumns: ["service_id","tenant_id"]
    },{
      foreignKeyName: "service_staff_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "services"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_staff_id_branch_id_fkey"
      columns: ["staff_id","branch_id"]
isOneToOne: false
      referencedRelation: "staff_branch_assignments"
      referencedColumns: ["staff_id","branch_id"]
    },{
      foreignKeyName: "service_staff_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                }
          }
          Functions: {
            "apply_membership_change":
{ Args: { "p_action": string,"p_actor": string,"p_branch_id"?: string,"p_membership_id"?: string,"p_role"?: string,"p_tenant_id": string,"p_user_id"?: string }; Returns: string
                           },
"archive_branch":
{ Args: { "p_branch_id": string }; Returns: undefined
                           },
"authorize_branch":
{ Args: { "p_branch_id": string,"p_roles": (string)[] }; Returns: string
                           },
"authorize_tenant_owner":
{ Args: { "p_tenant_id": string }; Returns: undefined
                           },
"blocked_time_actor_may_write":
{ Args: { "p_actor": string,"p_all_branches": boolean,"p_branch_id": string,"p_staff_id": string,"p_tenant_id": string }; Returns: boolean
                           },
"blocked_time_check_conflicts":
{ Args: { "p_ends_at": string,"p_ignore_id": string,"p_staff_id": string,"p_starts_at": string }; Returns: undefined
                           },
"blocked_time_check_values":
{ Args: { "p_blocked_time_type_id": string,"p_ends_at": string,"p_starts_at": string,"p_tenant_id": string }; Returns: undefined
                           },
"branch_staff_schedule":
{ Args: { "p_branch_id": string,"p_from": string,"p_tenant_id": string,"p_to": string }; Returns: {
              "all_branches": boolean,"blocked_time_type_id": string,"branch_id": string,"ends_at": string,"entry_id": string,"entry_type": string,"notes": string,"staff_id": string,"starts_at": string
            }[]
                           },
"can_grant_role":
{ Args: { "p_actor": string,"p_branch_id": string,"p_role": string,"p_tenant_id": string }; Returns: boolean
                           },
"catalogue_actor_is_owner":
{ Args: { "p_actor": string,"p_tenant_id": string }; Returns: boolean
                           },
"catalogue_actor_manages_branch":
{ Args: { "p_actor": string,"p_branch_id": string,"p_tenant_id": string }; Returns: boolean
                           },
"colleague_profiles":
{ Args: { "p_tenant_id": string }; Returns: {
              "avatar_url": string,"full_name": string,"id": string
            }[]
                           },
"copy_shift_week":
{ Args: { "p_actor": string,"p_branch_id": string,"p_replace": boolean,"p_source_week": string,"p_staff_ids": (string)[],"p_target_week": string,"p_tenant_id": string }; Returns: Json
                           },
"create_blocked_time":
{ Args: { "p_all_branches": boolean,"p_blocked_time_type_id": string,"p_branch_id": string,"p_ends_at": string,"p_notes"?: string,"p_staff_id": string,"p_starts_at": string,"p_tenant_id": string }; Returns: string
                           },
"create_branch":
{ Args: { "p_branch": Json,"p_hours"?: Json,"p_tenant_id": string }; Returns: string
                           },
"current_branch_scope":
{ Args: { "p_tenant_id": string }; Returns: string[]
                           },
"current_staff_ids":
{ Args: Record<PropertyKey, never>; Returns: string[]
                           },
"current_tenant_ids":
{ Args: Record<PropertyKey, never>; Returns: string[]
                           },
"default_branch_hours":
{ Args: Record<PropertyKey, never>; Returns: Json
                           },
"delete_blocked_time":
{ Args: { "p_id": string,"p_tenant_id": string }; Returns: undefined
                           },
"delete_closed_period":
{ Args: { "p_id": string }; Returns: undefined
                           },
"find_user_id_by_email":
{ Args: { "p_email": string }; Returns: string
                           },
"has_tenant_role":
{ Args: { "p_branch_id": string,"p_roles": (string)[],"p_tenant_id": string }; Returns: boolean
                           },
"has_tenant_role_any_branch":
{ Args: { "p_roles": (string)[],"p_tenant_id": string }; Returns: boolean
                           },
"holds_membership_authority":
{ Args: { "p_actor": string,"p_branch_id": string,"p_role": string,"p_tenant_id": string }; Returns: boolean
                           },
"is_valid_timezone":
{ Args: { "p_timezone": string }; Returns: boolean
                           },
"jsonb_text_array":
{ Args: { "p_value": Json }; Returns: (string)[]
                           },
"link_staff_login":
{ Args: { "p_actor": string,"p_staff_id": string,"p_tenant_id": string,"p_user_id": string }; Returns: undefined
                           },
"list_tenant_members":
{ Args: { "p_tenant_id": string }; Returns: {
              "all_branches": boolean,"branch_id": string,"created_at": string,"email": string,"full_name": string,"invite_pending": boolean,"is_active": boolean,"membership_id": string,"role": string,"user_id": string
            }[]
                           },
"my_assignments":
{ Args: { "p_tenant_id": string }; Returns: {
              "branch_id": string,"branch_is_active": boolean,"branch_name_ar": string,"branch_name_en": string,"first_day_of_week": number,"is_bookable": boolean,"is_default": boolean,"staff_id": string,"time_format": number,"timezone": string
            }[]
                           },
"next_counter_value":
{ Args: { "p_branch_id": string,"p_kind": string }; Returns: number
                           },
"normalize_search":
{ Args: { "p_value": string }; Returns: string
                           },
"provision_branch":
{ Args: { "p_branch": Json,"p_hours": Json,"p_requested_by": string,"p_tenant_id": string }; Returns: Json
                           },
"provision_branch_core":
{ Args: { "p_branch": Json,"p_hours": Json,"p_tenant_id": string }; Returns: string
                           },
"provision_tenant":
{ Args: { "p_branch": Json,"p_owner_id": string,"p_requested_by": string,"p_tenant": Json }; Returns: Json
                           },
"reorder_catalogue":
{ Args: { "p_actor": string,"p_category_id": string,"p_ids": (string)[],"p_kind": string,"p_tenant_id": string }; Returns: undefined
                           },
"replace_branch_hours":
{ Args: { "p_branch_id": string,"p_hours": Json }; Returns: undefined
                           },
"resolve_service":
{ Args: { "p_branch_id": string,"p_service_id": string }; Returns: {
              "branch_id": string,"buffer_after_minutes": number,"buffer_before_minutes": number,"duration_minutes": number,"is_enabled": boolean,"price_minor": number,"service_id": string,"service_name_ar": string,"service_name_en": string,"tenant_id": string
            }[]
                           },
"restore_branch":
{ Args: { "p_branch_id": string }; Returns: undefined
                           },
"seed_tenant_catalogues":
{ Args: { "p_tenant_id": string }; Returns: undefined
                           },
"set_blocked_time_type_active":
{ Args: { "p_id": string,"p_is_active": boolean }; Returns: undefined
                           },
"set_cancellation_reason_active":
{ Args: { "p_id": string,"p_is_active": boolean }; Returns: undefined
                           },
"staff_actor_has_authority":
{ Args: { "p_actor": string,"p_staff_id": string,"p_tenant_id": string }; Returns: boolean
                           },
"staff_actor_is_tenant_wide":
{ Args: { "p_actor": string,"p_tenant_id": string }; Returns: boolean
                           },
"staff_actor_manages_branch":
{ Args: { "p_actor": string,"p_branch_id": string,"p_tenant_id": string }; Returns: boolean
                           },
"staff_assigned_at":
{ Args: { "p_branch_id": string,"p_staff_id": string }; Returns: boolean
                           },
"staff_in_caller_branches":
{ Args: { "p_roles": (string)[],"p_staff_id": string,"p_tenant_id": string }; Returns: boolean
                           },
"staff_login_status":
{ Args: { "p_staff_id": string,"p_tenant_id": string }; Returns: {
              "invite_pending": boolean,"login_email": string,"user_id": string
            }[]
                           },
"staff_schedulable_at":
{ Args: { "p_branch_id": string,"p_staff_id": string }; Returns: boolean
                           },
"tenant_currency_locked":
{ Args: { "p_tenant_id": string }; Returns: boolean
                           },
"tenant_has_feature":
{ Args: { "p_feature": string,"p_tenant_id": string }; Returns: boolean
                           },
"update_blocked_time":
{ Args: { "p_blocked_time_type_id": string,"p_ends_at": string,"p_id": string,"p_notes"?: string,"p_starts_at": string,"p_tenant_id": string }; Returns: undefined
                           },
"update_branch":
{ Args: { "p_branch_id": string,"p_patch": Json }; Returns: undefined
                           },
"update_tenant_details":
{ Args: { "p_patch": Json,"p_tenant_id": string }; Returns: undefined
                           },
"upsert_blocked_time_type":
{ Args: { "p_color": string,"p_id"?: string,"p_name_ar": string,"p_name_en": string,"p_sort_order"?: number,"p_tenant_id": string }; Returns: string
                           },
"upsert_cancellation_reason":
{ Args: { "p_id"?: string,"p_name_ar": string,"p_name_en": string,"p_sort_order"?: number,"p_tenant_id": string }; Returns: string
                           },
"upsert_closed_period":
{ Args: { "p_branch_id": string,"p_ends_on": string,"p_id"?: string,"p_name_ar": string,"p_name_en": string,"p_starts_on": string }; Returns: string
                           },
"upsert_service":
{ Args: { "p_actor": string,"p_service": Json,"p_tenant_id": string }; Returns: string
                           },
"upsert_staff_member":
{ Args: { "p_actor": string,"p_staff": Json,"p_tenant_id": string }; Returns: string
                           },
"write_branch_hours":
{ Args: { "p_branch_id": string,"p_hours": Json,"p_tenant_id": string }; Returns: undefined
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        }
}

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
  ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
      Row: infer R
    }
    ? R
    : never
  : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Insert: infer I
    }
    ? I
    : never
  : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Update: infer U
    }
    ? U
    : never
  : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
  ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
  : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
  ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
  : never

export const Constants = {
  "graphql_public": {
          Enums: {
            
          }
        },"public": {
          Enums: {
            
          }
        }
} as const
